import glob
import os
import shutil

import numpy as np


class Progenitor:
    def __init__(self, m, m_he_core, z, model_name, model_number):
        self.m = m
        self.m_he_core = m_he_core
        self.z = z
        self.model_name = model_name
        self.model_number = model_number

    def calculate_y(self):
        y_primordial = 0.249  # Planck Collaboration (2015)
        y_protosolar = 0.2703  # AGSS09
        z_protosolar = 0.0142  # AGSS09
        # Choi et al. (2016)
        return y_primordial + (y_protosolar - y_primordial) * self.z / z_protosolar


def make_replacements(file_in, file_out, replacements, remove_original=False):
    with open(file_in) as infile, open(file_out, 'w') as outfile:
        for line in infile:
            for src, target in replacements.items():
                line = line.replace(src, target)
            outfile.write(line)
    if remove_original:
        os.remove(file_in)


if __name__ == "__main__":

    grid_name = "sdb"
    job_description = "work_" + grid_name
    template = "work-r11701"
    progenitors_dir = "../progenitors/"

    #########################################################################################

    progenitors = [
        Progenitor(1.0, 0.475052, 0.0142, "rgb_m1.0_z0.0142_y0.2703_fh0.0.mod", 15020), \
        # Progenitor(2.2, 0.393535, 0.0142, "rgb_m2.2_z0.0142_y0.2703_fh0.0.mod", 4060), \
    ]

    envelope_mass = np.unique(np.concatenate((
        np.arange(1e-4, 1.1e-3, 1e-4),
        np.arange(1e-3, 6e-3, 1e-3))))

    # availiable mixing types:
    # "std" - standard mixing
    # "cpm" - the convective premixing scheme
    # "predictive" - predictive mixing
    mixing = ["cpm"]

    f_he = [0.0]

    #########################################################################################

    for pro in progenitors:
        for m_env in envelope_mass:
            for mix in mixing:
                for f_core in f_he:
                    y = pro.calculate_y()
                    job_name = "m" + "{:.3f}".format(pro.m) + \
                        "_mcore" + "{:.6f}".format(pro.m_he_core) + \
                        "_menv" + "{:.5f}".format(m_env) + \
                        "_z" + "{:.4f}".format(pro.z) + \
                        "_y" + "{:.5f}".format(y) + \
                        "_fhe" + "{:.3f}".format(f_core) + \
                        "_" + mix
                    print(job_name)
                    dest_dir = job_description + "_" + job_name
                    shutil.copytree(template, dest_dir)
                    shutil.move(dest_dir + "/run_make_sdb.sh", dest_dir + "/r_" + grid_name + "_" +
                                job_name + ".sh")
                    replacements = {
                        "[[MASS]]": "{:.3f}".format(pro.m),
                        "[[M_HE_CORE]]": "{:.6f}".format(pro.m_he_core),
                        "[[Z]]": "{:.4f}".format(pro.z),
                        "[[Y]]": "{:.5f}".format(y),
                        "[[MODEL_NAME]]": os.path.join(progenitors_dir, pro.model_name),
                        "[[M_ENV]]": "{:.5f}".format(m_env),
                        "[[MIXING]]": mix,
                        "[[F_HE]]": "{:.3f}".format(f_core)
                    }
                    make_replacements(dest_dir + '/template_r11701.rb', dest_dir + '/make_sdb.rb',
                                      replacements)
