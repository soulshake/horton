horton

A bash script wrapper for whois.  Primary purpose is to filter whois output to remove "irrelevant" (to the author) sections from a single run of whois with a supplied domain.

Usage is horton [-v] domain

The domain can be supplied as a dotted-decimal IPv4 address, a domain name, or a URL (from which the domain can be extracted.) In addition, if =domain is used, the equals will be passed intact to whois for disambiguation.

The -v switch triggers verbose mode which displays the filtered text in an alternate color (using tput.)  Normally the filtered results do not display at all.

At the end of the run, the script will send the final non-filtered output to the default text editor on Mac OS X (GUI) systems.

This feature in conjunction with the -v (verbose) switch allows the user to see, in Terminal both filtered (colored) and unfiltered text inline while also still providing the clean filtered text via the GUI text editor.

The script makes use of external files stored at horton/files/, which allow easily adding snippets of text from text-blocks to be filtered out (using the exclude lists), or via the "include" lists, to specifically not be filtered / removed from the final output. Additionally, sed rules are also stored as external files.  The sed rules are predominantly used to add or remove line endings within the whois output to split the output into blocks of text making it possible to reject entire blocks instead of individual lines of endlessly varying verbiage.

The script is well commented.

A future addition to the project will be a secondary script to optimize the main horton script to improve overall speed (not that it's such a problem for one-at-a-time whois lookup and filtering.)

Dependencies:
whois
sed
tr
rev
cut
sort
grep
TextEdit or other OS X GUI text editor for optional final output to new document window

Written using bash 4.2.45, tested with bash 2.05b - both on Mac OS X.