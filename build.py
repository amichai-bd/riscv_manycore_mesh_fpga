import os
import subprocess
import glob
import argparse
from termcolor import colored

examples = '''
Examples:
python build.py -proj_name 'big_core' -debug -all -full_run                      -> running full test (app, hw, sim) for all the tests and keeping the outputs 
python build.py -proj_name 'big_core'        -all -full_run                      -> running full test (app, hw, sim) for all the tests and removing the outputs 
python build.py -proj_name 'big_core' -debug -tests 'alive plus_test' -full_run  -> run full test (app, hw, sim) for alive & plus_test only 
python build.py -proj_name 'big_core' -debug -tests 'alive' -app                 -> compiling the sw for 'alive' test only 
python build.py -proj_name 'big_core' -debug -tests 'alive' -hw                  -> compiling the hw for 'alive' test only 
python build.py -proj_name 'big_core' -debug -tests 'alive' -sim -gui            -> running simulation with gui for 'alive' test only 
'''
parser = argparse.ArgumentParser(description='Build script for any project', formatter_class=argparse.RawDescriptionHelpFormatter, epilog=examples)
parser.add_argument('-all', action='store_true', default=False, help='running all the tests')
parser.add_argument('-tests', default='', help='list of the tests for run the script on')
parser.add_argument('-debug', action='store_true', help='run simulation with debug flag')
parser.add_argument('-gui', action='store_true', help='run simulation with gui')
parser.add_argument('-app', action='store_true', help='compile the RISCV SW into SV executables')
parser.add_argument('-hw', action='store_true', help='compile the RISCV HW into simulation')
parser.add_argument('-sim', action='store_true', help='start simulation')
parser.add_argument('-full_run', action='store_true', help='compile SW, HW of the test and simulate it')
parser.add_argument('-proj_name', default='big_core', help='insert your project name (as mentioned in the dirs name')
parser.print_help()
args = parser.parse_args()

MODEL_ROOT = subprocess.check_output('git rev-parse --show-toplevel', shell=True).decode().split('\n')[0]
VERIF = './verif/'+args.proj_name+'/'
TB = './verif/'+args.proj_name+'/tb/'
MODELSIM = './modelsim/'+args.proj_name+'/'
SOURCE = './source/'+args.proj_name+'/'
TARGET = './target/'+args.proj_name+'/'
APP = './app/'
TESTS = './verif/'+args.proj_name+'/tests/'

#####################################################################################################
#                                           class Test
#####################################################################################################
class Test:
    hw_compilation = False
    def __init__(self, name, project):
        self.name = name.split('.')[0]
        self.file_name = name
        self.assembly = True if self.file_name[-1] == 's' else False
        self.project = project 
        self.target , self.gcc_dir = self._create_test_dir()
        self.path = TESTS+self.file_name
        self.fail_flag = False
    def _create_test_dir(self):
        if not os.path.exists(TARGET+'tests'):
            os.mkdir(TARGET+'tests')
        if not os.path.exists(TARGET+'tests/'+self.name):
            os.mkdir(TARGET+'tests/'+self.name)
        if not os.path.exists(TARGET+'tests/'+self.name+'/gcc_files'):
            os.mkdir(TARGET+'tests/'+self.name+'/gcc_files')
        return TARGET+'tests/'+self.name+'/', TARGET+'tests/'+self.name+'/gcc_files'
    def _compile_sw(self):
        print_message('[INFO] Starting to compile SW ...')
        if self.path:
            cs_path =  self.name+'_rv32i.c.s' if not self.assembly else '../../../../../'+self.path
            elf_path = self.name+'_rv32i.elf'
            txt_path = self.name+'_rv32i_elf.txt'
            os.chdir(self.gcc_dir)
            try:
                if not self.assembly:
                    first_cmd  = 'riscv-none-embed-gcc.exe     -S -ffreestanding -march=rv32i ../../../../../'+self.path+' -o '+cs_path
                    subprocess.check_output(first_cmd, shell=True)
                else:
                    pass
            except:
                print_message(f'[ERROR] failed to gcc the test - {self.name}')
                self.fail_flag = True
            else:
                try:
                    second_cmd = 'riscv-none-embed-gcc.exe  -O3 -march=rv32i -T ../../../../../app/link.common.ld\
                                    -Wl,--defsym=I_MEM_OFFSET=0x00000000\
                                    -Wl,--defsym=I_MEM_LENGTH=0x00002000\
                                    -Wl,--defsym=D_MEM_OFFSET=0x00002000\
                                    -Wl,--defsym=D_MEM_LENGTH=0x00002000\
                                    -nostartfiles -D__riscv__ ../../../../../app/crt0.S '+cs_path+' -o '+elf_path
                    subprocess.check_output(second_cmd, shell=True)
                except:
                    print_message(f'[ERROR] failed to insert linker & crt0.S to the test - {self.name}')
                    self.fail_flag = True
                else:
                    try:
                        third_cmd  = 'riscv-none-embed-objdump.exe -gd {} > {}'.format(elf_path, txt_path)
                        subprocess.check_output(third_cmd, shell=True)
                    except:
                        print_message(f'[ERROR] failed to create "elf.txt" to the test - {self.name}')
                        self.fail_flag = True
                    else:
                        try:
                            forth_cmd  = 'riscv-none-embed-objcopy.exe --srec-len 1 --output-target=verilog '+elf_path+' inst_mem.sv' 
                            subprocess.check_output(forth_cmd, shell=True)
                        except:
                            print_message(f'[ERROR] failed to create "inst_mem.sv" to the test - {self.name}')
                            self.fail_flag = True
            if not self.fail_flag:
                print_message('[INFO] SW compiation finished with no errors\n')
        else:
            print_message('[ERROR] Can\'t find the c files of '+self.name)
            self.fail_flag = True
        os.chdir(MODEL_ROOT)
    def _compile_hw(self):
        os.chdir(MODELSIM)
        print_message('[INFO] Starting to compile HW ...')
        if not Test.hw_compilation:
            comp_sim_cmd = 'vlog.exe -lint -f ../../'+TB+'/'+self.project+'_list.f'
            try:
                #results = subprocess.check_output(comp_sim_cmd, shell=True, stderr=subprocess.STDOUT).decode()
                results = subprocess.run(comp_sim_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
            except:
                print_message('[ERROR] Failed to compile simulation of '+self.name)
                self.fail_flag = True
            else:
                Test.hw_compilation = True
                if len(results.stdout.split('Error')) > 2:
                    print(results.stdout)
                    self.fail_flag = True
                else:
                    print_message('[INFO] hw compilation finished with - '+','.join(results.stdout.split('\n')[-2:-1])+'\n')
        else:
            print_message(f'[INFO] HW copilation is already done\n')
        os.chdir(MODEL_ROOT)
    def _start_simulation(self):
        os.chdir(MODELSIM)
        print_message('[INFO] Now running simulation ...')
        sim_cmd = 'vsim.exe work.'+self.project+'_tb -c -do "run -all" +STRING='+self.name
        try:
            results = subprocess.run(sim_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        except:
            print_message('[ERROR] Failed to simulate '+self.name)
            self.fail_flag = True
        else:
            if len(results.stdout.split('Error')) > 2 or len(results.stdout.split('Warning')) > 2:
                print(results.stdout)
                if len(results.stdout.split('Error')) > 2:
                    self.fail_flag = True
            else:
                print_message('[INFO] hw simulation finished with - '+','.join(results.stdout.split('\n')[-2:-1]))
        os.chdir(MODEL_ROOT)
    def _gui(self):
        os.chdir(MODELSIM)
        gui_cmd = 'vsim.exe -gui work.'+self.project+'_tb +STRING='+self.name+' &'
        try:
            subprocess.call(gui_cmd, shell=True)
        except:
            print_message('[ERROR] Failed to run gui of '+self.name)
            self.fail_flag = True
        os.chdir(MODEL_ROOT)
    def _no_debug(self):
        delete_cmd = 'rm -rf '+TARGET+'tests/'+self.name
        try:
            subprocess.check_output(delete_cmd, shell=True)
        except:
            print_message('[ERROR] failed to remove /target/'+self.project+'/tests/'+self.name+' directory')

def print_message(msg):
    msg_type = msg.split()[0]
    color = 'red' if msg_type == '[ERROR]' else 'yellow' if msg_type == '[WARNING]' else 'white' if msg_type == '[INFO]' else 'blue'
    print(colored(msg,color,attrs=['bold']))        

#####################################################################################################
#                                           main
#####################################################################################################       
def main():
    
    os.chdir(MODEL_ROOT)
    tests = []
    if args.all:
        test_list = os.listdir(TESTS)
        print(f'test_list - {test_list}')
        for test in test_list:
            tests.append(Test(test, args.proj_name))
    else:
        print(args.tests)
        for test in args.tests.split():
            test = glob.glob(TESTS+test+'*')[0]
            test = test.replace('\\', '/').split('/')[-1]
            tests.append(Test(test, args.proj_name))
        
    for test in tests:
        print_message('******************************************************************************')
        print_message('                               Test - '+test.name)
        if (args.app or args.full_run) and not test.fail_flag:
            test._compile_sw()
        if (args.hw or args.full_run) and not test.fail_flag:
            test._compile_hw()
        if (args.sim or args.full_run) and not test.fail_flag:
            test._start_simulation()
        if (args.gui):
            test._gui()
        if not args.debug:
            test._no_debug()
        print_message('******************************************************************************')
    
if __name__ == "__main__" :
    main()      
