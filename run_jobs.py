import glob
import os

grid_name = 'sdb'

jobs_pattern = 'work_' + grid_name + '_*'
dirs = glob.glob(jobs_pattern)

top_dir = os.getcwd()
for folder in dirs:
    os.chdir(folder)
    script = glob.glob('r_*.sh')[0]
    os.system('qsub ' + script)
    os.chdir(top_dir)
