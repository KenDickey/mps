#!/bin/sh
# $Header$
#
# Copyright (C) 2004-2005 Ravenbrook Limited.  See end of file for license.
#
# expgen.sh
#
# Export Generator
#
# This is a script to generate the a list of exports that is required
# for Windows DLL creation.
#
# It processed the mps header files and produces a .DEF file that is
# suitable for use with the linker when producing a DLL file on Windows.
#
# When run, this script produces the following output files:
# expgen - a plain text list of functions declared in the header files.
# w3gen.def - a .def file suitable for use in the linker stage when
# building a Windows .DLL.
#
# Procedure for rebuilding a new w3gen.def
#
# This procedure should be carried out when the contents of w3gen.def
# would change.  This is a bit tricky to say exactly when, but certainly
# when:
# a) new functions are declared in public header files.
# b) different header files are released to a client.
#
# Procedure:
#
# 0) Note: This procedure worked with gcc 3.3 "gcc (GCC) 3.3 20030304 
# (Apple Computer, Inc. build 1495)", running on Mac OS X 10.3.
# However, at 2005-10-12, with gcc 4.0 "gcc version 4.0.0 (Apple 
# Computer, Inc. build 5026)", running on Mac OS X 10.4.2, it did not 
# work.  Invoking "gcc -fdump-translation-unit spong.h" did not produce 
# a "spong.h.tu" file.  
#
# 1) Ensure that the sources for w3gen.def are submitted.  w3gen.def
# must be built from versioned sources.
# The sources are:
# expgen.sh
# w3build.bat
# all the headers that get included.
# For safety's sake better to ensure that no files are open:
# p4 opened ...
# should say '... - file(s) not opened on this client.'
#
# 2) Open w3gen.def for edit (making it writable)
# p4 open w3gen.def
#
# 3) Run this script.
# sh expgen.sh
# There should be no output when successful.
#
# 4) Eyeball the diff.
# p4 diff ...
# Check the that resulting diff is sane.  For most changes it should
# just consist of a new symbol being included (plus some Header related
# junk).
#
# 5) Submit the change.
# p4 submit ...
#
#
# Design
#
# The script works by using the -fdump-translation-unit option of gcc.
# This produces a more easily parseable rendering of the header files.
# A fairly simple awk script is used to process the output.
#
#
# Dependencies
#
# This script currently depends fairly heavily on being run in a
# Unix-like environment with access to the GNU compiler.
#
# It's also fairly sensitive to changes in the undocumented format
# produced by gcc -fdump-translation-unit.  Hopefully it is fairly easy
# to adapt to changes in this output.
#
# Assumes it can freely write to the files "fun", "name-s".
#
#
# Awk crash course
#
# Awk processes files line-by-line, thus the entire script is executed
# for each line of the input file (more complex awk scripts can control
# this using "next" and "getline" and so on).
#
# In awk $exp identifies a field within the line.  $1 is the first
# field, $2 is the second and so on.  $0 is the whole line.  By default
# fields are separated by whitespace.
#
# string ~ RE is a matching expression and evaulated to true iff the
# string is matched by the regular expression.
#
# REFERENCES
#
# [SUSV3] Single UNIX Specification Version 3,
# http://www.unix.org/single_unix_specification/
#
# For documenation of the standard utilities: sh, awk, join, sort, sed
#
# [MSDN-LINKER-DEF] Module-Definition (.def) files,
# http://msdn.microsoft.com/library/default.asp?url=/library/en-us/vccore/html/_core_module.2d.definition_files.asp
#
# For documentation on the format of .def files.

tu () {
  # if invoked on a file called spong.h will produce a file named
  # spong.h.tu
  gcc -fdump-translation-unit -o /dev/null "$@"
}

# This list of header files is produced by
# awk '/^copy.*\.h/{print $2}' w3build.bat
# followed by manual removal of mpsw3.h mpswin.h (which gcc on UNIX
# cannot parse).  Also removed are mpsio.h mpslib.h as they defined
# interfaces that mps _uses_ not defines.  Also removed is mpscmvff.h as
# it does not get included in mps.lib.  Also removed is mpslibcb.h, 
# which now has its own mpslibcb.def file (job002148).
# The functions declared in mpsw3.h have to be added to the .def file by
# hand later in this script.
f='mps.h
mpsavm.h
mpsacl.h
mpscamc.h
mpscams.h
mpscawl.h
mpsclo.h
mpscmv.h
mpscsnc.h
mpstd.h'

tu $f

>expgen

for a in $f
do
  >fun
  awk '
    $2=="function_decl" && $7=="srcp:" && $8 ~ /^'$a':/ {print $4 >"fun"}
    $2=="identifier_node"{print $1,$4}
  ' $a.tu |
  sort -k 1 >name-s

  echo ';' $a >>expgen
  sort -k 1 fun |
    join -o 2.2 - name-s >>expgen
done

{
  printf '; %sHeader%s\n' '$' '$'
  echo '; DO NOT EDIT.  Automatically generated by $Header$' | sed 's/\$/!/g'
  echo 'EXPORTS'
  cat expgen
  # This is where we manually the functions declared in mpsw3.h
  echo ';' mpsw3.h - by hand
  echo mps_SEH_filter
  echo mps_SEH_handler
} > w3gen.def


# C. COPYRIGHT AND LICENSE
#
# Copyright (C) 2004-2005 Ravenbrook Limited <http://www.ravenbrook.com/>.
# All rights reserved.  This is an open source license.  Contact
# Ravenbrook for commercial licensing options.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Redistributions in any form must be accompanied by information on how
# to obtain complete source code for this software and any accompanying
# software that uses this software.  The source code must either be
# included in the distribution or be available for no more than the cost
# of distribution plus a nominal fee, and must be freely redistributable
# under reasonable conditions.  For an executable file, complete source
# code means the source code for all modules it contains. It does not
# include source code for modules or files that typically accompany the
# major components of the operating system on which the executable file
# runs.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE, OR NON-INFRINGEMENT, ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
