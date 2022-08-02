#!/bin/bash

PORT=$(awk "BEGIN{srand();print int(rand()*(63000-2000))+2000 }")

# select the tool you use (true=notebook, false=lab)!!
JUPYTERBOOK_OR_LAB=false

# the following has to be changed by the  user !!
SLURM_TASKS="1"
SLURM_CPUS_PER_TASK="8"
SLURM_MEM="32gb"
SLURM_PARTITION="jupyter"
# if you use gpus redefine "SLURM_GPUs" or uncomment both following line if you are not using the gpus
#SLURM_PARTITION="gpu"
# only use this if you need more than 1 gpu
SLURM_GPUs=1

# create run.sh
FILE2RUN="jupyter_run.sh"
LOG="jupyter_run.log"
touch $LOG
function create_run_file {
    cat "./$FILE2RUN" > "./$FILE2RUN"
    echo "#!/bin/bash" >> "./$FILE2RUN"
    echo "#SBATCH --job-name=jupyter" >> "./$FILE2RUN"
    echo "#SBATCH --output=$LOG" >> "./$FILE2RUN"
    echo "#SBATCH --ntasks=$SLURM_TASKS" >> "./$FILE2RUN"
    echo "#SBATCH --mem=$SLURM_MEM" >> "./$FILE2RUN"
    echo "#SBATCH --cpus-per-task=$SLURM_CPUS_PER_TASK" >> "./$FILE2RUN"
    echo "#SBATCH --partition=$SLURM_PARTITION" >> "./$FILE2RUN"
    if [[ $SLURM_GPUs ]]; then
		echo "#SBATCH --gres=gpu:$SLURM_GPUs" >> "./$FILE2RUN"
	else
		echo "#SBATCH --gres=gpu:1" >> "./$FILE2RUN"
	fi
    echo >> "./$FILE2RUN"
    echo 'echo "DATE:$(date)"' >> "./$FILE2RUN"
    echo 'echo "HOST:$(hostname)"' >> "./$FILE2RUN"
    echo 'echo "WORK_DIR:$(pwd)"' >> "./$FILE2RUN"
    echo >> "./$FILE2RUN"
    #adapt the next line according to your needs (you must have installed jupyterlab in your virtual environment)
    echo 'conda activate /mnt/work/python/dkottke/pytorch' >> "./$FILE2RUN"
    if $JUPYTERBOOK_OR_LAB; then
        echo "srun jupyter-notebook --port=\$1" >> "./$FILE2RUN"
    else
        echo "srun jupyter lab --port=\$1" >> "./$FILE2RUN"
    fi

    sleep 1
}
create_run_file

# from here on change carefull something !!
DATE="unknown"
HOST="unknown"
WORK_DIR="unknown"
TOKEN="unknown"

# jupyter notebook server has to be up and running, than this script is able to kill the job
echo "Jupyter Notebook or Lab job is starting"
trap '' INT TSTP

SBATCH_OUT="$(sbatch $FILE2RUN $PORT &)"
sleep 6
while ! grep '?token=' $LOG -q --max-count=1; do sleep 2;done

JOB_ID=${SBATCH_OUT##*job }

#extract data from log-file
DATE_LINE="$(grep 'DATE:' $LOG --max-count=1)"
DATE=${DATE_LINE##*DATE:}

HOST_LINE="$(grep 'HOST:' $LOG --max-count=1)"
HOST=${HOST_LINE##*HOST:}

WORK_DIR_LINE="$(grep 'WORK_DIR:' $LOG --max-count=1)"
WORK_DIR=${WORK_DIR_LINE##*WORK_DIR:}

TOKEN_LINE="$(grep '?token=' $LOG --max-count=1)"
TOKEN=${TOKEN_LINE##*?token=}

# print state
echo $DATE
echo "Jupyter Notebook is running (JOB_ID=$JOB_ID)"
echo "Working directory:"
echo -e "\t$WORK_DIR"
echo
echo "Open tunnel to server:"
echo -e "\tssh -N -L$PORT:localhost:$PORT $HOST.ies"
echo
echo "To access the notebook copy and paste one of these URLs:"
echo -e "\thttp://localhost:$PORT/?token=$TOKEN"
echo -e "\thttp://127.0.0.1:$PORT/?token=$TOKEN"
echo -e "\n\n"


function ctrl_c {
    while true; do
        read -p "Do you wish to cancel the Jupyter Notebook or Lab (JOB_ID=$JOB_ID)? [Yy/Nn]" yn
        case $yn in
            [Yy]* ) trap SIGINT; scancel $JOB_ID; exit;; #rm $LOG; rm $FILE2RUN; exit;;
            [Nn]* ) break;;
        esac
    done
}
trap ctrl_c INT

#squeue
while true; do
    sleep inf
done

