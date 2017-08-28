<br>

#### PURPOSE

Today we will work on downloading data files from the NCES and OECD
databases. While these data files represent only a fraction of publicly
available data (which themselves are only a fraction of all potentially
available data), they are some of the most widely used in education
research.

<br>

EDAT
----

NCES has created a very useful data tool called EDAT, which I assume
stands for something clever. The intent behind this web-based
application is to allow you to select the variables that you would like
to work with, then to generate syntax (in our case, do files) that will
allow you to access this data. Today, we'll go through how to generate a
very basic analysis dataset from all four of the surveys that you will
be working with as a group. The process for each is broadly the same:

-   Select variables
-   Download syntax and data (only need to download the data the
    first time)
-   Adjust syntax as appropriate (rewrite do-file to our specifications)
-   Generate analysis dataset

This process, like all other work, should be tracked carefully. Some
simple steps at the beginning can save you lots of time at the end.

I will also show you how to download the full datasets for each survey
today. While EDAT may entirely serve your data-gathering needs (at least
for these surveys), you may in the future easier to simply gather all of
available data on your computer with a few lines of code, avoiding the
point-and-click aspects of EDAT altogether and increasing the
reproducibility of your project.

<br>

Directory structure
-------------------

First things first, let's add to our directory structure. As you
remember from the first lecture, data files and Stata do files have been
stored in their own subdirectories. While it's possible to simply dump
everything in one big directory, you may find that over time, as the
folder grows, it becomes very difficult to find what you need and almost
impossible to share your work with others. Yes, your computer can search
really well. An organized directory structure is for you, the human. Get
into the habit now, and you'll be thankful later.

Today we're adding an `./aux` subdirectory. Your directory structure
should now look like this:

    .
    |-- /aux
    |   |
    |   |-- <auxiliary files>
    |
    |-- /data
    |   |
    |   |-- <data files>
    |
    |-- /do
    |   |
    |   |-- <Stata do files>
    |
    |-- /plots
    |   |
    |   |-- <plot files>

<br>

Global variables (macros)
-------------------------

Now that your project/course directory is structured this way, it is
very easy to find files across subdirectories. But rather than retype
something like `../data/` in front of every data file name, it is useful
to store the relative link name in a type of variable that we can then
call as we want. One type of variable that Stata allows us to use for
this procedure (among others) is called a global variable or macro. See
the top part of the do file for an example of how to store a relative
path in a global variable:

    . global workdir `c(pwd)'

    . global datadir "../../data/"

    . global auxdir "../../aux/"

Note that globals follow the pattern: `global <name> <value>`. To call a
global macro in Stata, you place a `$` in front of the name you gave it.
Stata will replace that with the value. Here are some examples with
`display`:

    . di "$workdir"
    /Users/doylewr/practicum/fall_2016/central/lessons/nces_datasets

    . di "$datadir"
    ../../data/

#### NOTE: Most calls of the Stata global macro do not require quotation marks. That is a quirk of Stata's `display` command.

<br>

Educational Longitudinal Study, 2002 (ELS)
------------------------------------------

<br>

### Unzip data

Prior to running this file, we will have to have downloaded the entirety
of the ELS student file. While this may seem like overkill, note that
even if you use EDAT and subset the variables you actually want, you
will end up downloading all of ELS anyway (just the way it works).
First, let's set new globals:

    . global els_zip "ELS_2002-12_PETS_v1_0_Student_Stata_Datasets.zip"

    . global els_dta "els_02_12_byf3pststu_v1_0.dta"

    . global elssave "els_reduced.dta"

As you probably noticed, the downloaded ELS file is zipped. This means
that we need to unzip it with `unzipfile`. Stata will only unzip a file
into the current directory, so in order to have it go into our data
directory like we want, we need to use the `cd` command to change
directory into our data directory and return to the working directory
after we've unzipped the file. This is why we saved the `workdir` at the
top of the file.

    . cd $datadir
    /Users/doylewr/practicum/fall_2016/central/data

    . unzipfile $els_zip, replace
        inflating: els_02_12_byf3pststu_v1_0.dta
    successfully unzipped ELS_2002-12_PETS_v1_0_Student_Stata_Datasets.zip to cur
    > rent directory

    . cd $workdir
    /Users/doylewr/practicum/fall_2016/central/lessons/nces_datasets

<br>

### Subset data

ELS data files are very large, so they take up a ton of memory if you
try to load them in their entirety. For any given project, you don't
want or need all of the variables anyway. To subset the full dataset to
only those variables we want requires the `use using` setup, as follows
(note how we temporariliy change the delimiter to make our lives a
little easier):

    . #delimit ;
    delimiter now ;
    . // keep only selected variables in ELS
    > use 
    >    STU_ID
    >    SCH_ID
    >    STRAT_ID
    >    PSU
    >    F1SCH_ID
    >    F1UNIV1
    >    F1UNIV2A
    >    F1UNIV2B
    >    F2UNIV_P
    >    BYSTUWT
    >    F1QWT
    >    F1PNLWT
    >    F1TRSCWT
    >    F2QTSCWT
    >    F2QWT
    >    F2F1WT
    >    F2BYWT
    > using $datadir$els_dta;

    . // change delimiter back to carriage return
    > #delimit cr
    delimiter now cr
    . // lower all variable names using wildcard
    . renvars *, lower

    . // save reduced ELS dataset
    . save $datadir$elssave, replace
    file ../../data/els_reduced.dta saved

Because nobody (nobody) likes variables with capital letters---except in
very specific sitations---we use the `renvars` command to set all the
variable names to lowercase. Once that is finished, we save the new
working dataset with `save` command. By prepending the name of the saved
dataset with the relative link to the data folder (via the global), the
save dataset goes into the correct subdirectory. The option after the
comma, `replace`, simply tells Stata to overwrite any files with same
name.

<br>

#### QUICK EXERCISE

> Using EDAT, generate an ELS dataset that includes student demographics
> and whether or not the student attended college.

<br>

Early Childhood Longitudinal Study - Kindergarten 98-99 (ECLS-K)
----------------------------------------------------------------

<br>

### Unzip data

Unzipping ECLS-K follows the same method that we used for ELS. Note that
the unzipped files is *really* big, so sure you have enough room for it
(no 2 GB thumbdrives!).
