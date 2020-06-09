import glob
import os
import shutil

log_dir = 'logs'

required_file = 'custom_He0.1.data'
top_dir = os.getcwd()
for folder in sorted(glob.glob(os.path.join(log_dir, 'logs_*'))):
    models = glob.glob(os.path.join(folder, 'custom_*.data'))
    custom_models = [os.path.basename(model) for model in models]
    if required_file in custom_models:
        print("OK " + folder)
        os.chdir(folder)
        script = glob.glob('g_*.sh')[0]
        os.system('qsub ' + script)
        os.chdir(top_dir)
    else:
        print("Removing " + folder)
        shutil.rmtree(folder)
