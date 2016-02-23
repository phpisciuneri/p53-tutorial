# P53 Tutorial

## Prerequisites

* Anaconda python.  [Available here.](https://www.continuum.io/downloads)  Be sure that the following packages are installed:

  - yaml
  - mpi4py
  
* WESTPA.  [Available here.](https://westpa.github.io/westpa/)
* GROMACS.  [Available here.](http://www.gromacs.org)

## Quick Start

1. Get the code and get inside:

   ```bash
   $ git clone https://github.com/phpisciuneri/p53-tutorial.git
   $ cd p53-tutorial
   ```
   
2. Set your environment:

	```bash
	$ . ./env.sh
	$
	$ module list
Currently Loaded Modulefiles:
  1) moab/8.1.0                     5) modules                        9) openmpi/1.6.5-gcc4.8.2-rhel
  2) torque/5.1                     6) sys                           10) gromacs/4.6.5-gcc-4.8.2-rhel
  3) mam/8.1.0                      7) gcc/4.8.2-rhel                11) python/anaconda2-2.4.1
  4) queue                          8) mkl/2013.0/gnu-st             12) westpa/anaconda2-2.4.1
   $
   $ echo $WEST_ROOT
/opt/sam/westpa-mpi
   $ which w_run
/opt/sam/westpa-mpi/bin/w_run
   $ which w_init
/opt/sam/westpa-mpi/bin/w_init
	```
   
3. Initialize the simulation:
   
   ```bash
   $ ./init.sh
   ```

4. Run the simulation:

   * Processes work manager: `$ qsub runwe_frank.job`
   * MPI work manager: `$ qsub runwe_mpi_frank.job`