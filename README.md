DP Test Phonebook
=================

Rails phonebook application with functions of export and import.

Import file
-----------

Import file is file of TSV format - lines of values separated from the next by a tab stop character ([wikipedia article](http://en.wikipedia.org/wiki/Tab-separated_values)).

**Import file can add new contact and/or phone numbers with line like**:

    Contact name	number	number ...

or:

    $#+ Contact name	number	number ...

- If app can't find `Contact name` in phonebook, new contact will be created
- If app find `Contact name` in phonebook, new `number`'s will be added to exist contact

Example: `John Doe	+1 (845) 637 2957	+37654329900`


**Import file can rename existing contacts with line like**:

    $#~	Old name	New name

- Rename work only if app find contact with name equal to `Old name`

Example: `$#~	John Doe	Jannet Doe`


**Import file can remove contacts with line like**:

    $#-	Contact name

and remove phone numbers from contact with line like:

    $#- Contact name number_for_remove number_for_remove ...

Example: `$#-	Jannet Doe	+37654329900` and `$#-	Jannet Doe`


Author: Dymio (mstrdymio@gmail.com)
