#!/usr/bin/env bash

#-----------------------------------------------------------------------------#

# My test system is "en_US.UTF-8", "xterm-color", bash 4.2.45, PPC/G4, Mac OS X Tiger/10.4.11

#-----------------------------------------------------------------------------#

# Dependencies:
# whois
# sed
# tr
# rev
# cut
# sort
# grep (ip address as input check, because it was quick and easy)
# TextEdit optional for final output to new document window

#-----------------------------------------------------------------------------#

# Five blank lines
# Preferring this method over jot for portability
echo -e "\n\n\n\n\n"

# Echo a line of 80 *s.  Preferring this method over jot for portability
a= ; until [ ${#a} -eq 80 ] ; do a="${a}*" ;  done ; echo "${a}"

echo "horton v1.8"
echo "whois output filter"
# Using susbstring of $0 instead of basename (external) for portability 
echo "Usage:  ${0##*/} [-v] domain"


# Echo another line of 80 *s
echo "${a}"

#-----------------------------------------------------------------------------#

# declare Variables
# Note, using substring of $0 instead of dirname (external) for portability
declare    a IFSold="${IFS}" newline=$'\n' AllText Verbose TheDomain Mode="Blocks" AlternateOutput="no" a FinalOutput MyDir="${0%\/*}" IsIP="no"
	   # Text color
declare    black=$(tput setaf 0) red=$(tput setaf 1) green=$(tput setaf 2) yellow=$(tput setaf 3) blue=$(tput setaf 4) magenta=$(tput setaf 5) cyan=$(tput setaf 6) white=$(tput setaf 7)
	   # Note, with white text, set background color via tput setab [0-7]
	   # Text style
declare    underline=$(tput smul) bold=$(tput bold) normal=$(tput sgr0)
declare -a TextBlocks List_CrapStartsWith List_CrapContains List_CrapIs List_GoodStuffStartsWith List_GoodStuffContains
declare -i i j

#-----------------------------------------------------------------------------#

# Read in the filter lists
IFS="${newline}" # This should be done before reading in the lists to ensure that only newlines will separate the entries
List_CrapStartsWith=( $( sort -u "${MyDir}/lists/exclude/CrapStartsWith.txt" ) )
List_CrapContains=( $( sort -u "${MyDir}/lists/exclude/CrapContains.txt" ) )
List_CrapIs=( $( sort -u "${MyDir}/lists/exclude/CrapIs.txt" ) )
List_GoodStuffStartsWith=( $( sort -u "${MyDir}/lists/include/GoodStuffStartsWith.txt" ) )
List_GoodStuffContains=( $( sort -u "${MyDir}/lists/include/GoodStuffContains.txt" ) )

#-----------------------------------------------------------------------------#

# Check command-line arguments (currently only -v supported)
# Allow -v command line argument for enabling verbose mode
if [ "${1}" = "-v" ] ; then
	Verbose="yes"
	TheDomain="${2:-ghandi.net}"
elif  [ "${2}" = "-v" ] ; then 
	# Noticed from dear cousin's output that she included switches AFTER data on cli. Sheesh.
	Verbose="yes"
	TheDomain="${1:-ghandi.net}"
else
	Verbose="no"
	TheDomain="${1:-ghandi.net}"
fi

#-----------------------------------------------------------------------------#

# Clean and check the specified domain input

# Detect if the input is a dotted decimal IP address
echo "${TheDomain}" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' && IsIP="yes"

# If the input is not a dotted decimal IP address then treat as URL or domain name
if [ "${IsIP}" != "yes" ] ; then
	# Lowercase it (because FUNPIC.DE doesn't work and funpic.de does.)
	# Extract the domain from the input so that input works with clumsy copying or full URL
	TheDomain=$( echo "${TheDomain}" | tr "A-Z" "a-z" | sed -e 's-^.*://--' -e 's-/.*$--' | rev | cut -d '.' -f 1-3  )
	
	# The domain input is now reversed, its backward via 'rev' above.
	# I did this because the important portions are at the end and it was easier to think through this with them at the beginning. I'm lazy like that.

	# If the domain doesn't end with either 2 chrs dot 2 chrs or 3 chrs dot 2 chrs, then lose the first segment
	# And when I say "end with" I mean "begin with" since we have reversed the line.	

	# If the domain does end with dot 2 chrs
	if [ "${TheDomain}" != "${TheDomain#??\.}" ] ; then
		# If the domain also does end with dot 2 dot 2 chrs
		if [ "${TheDomain}" != "${TheDomain#??\.??\.}" ] ; then
			: # do nothing because we need the first segment when it ends with dot 2 dot 2
		# If the domain also does NOT end with 3 dot 2 chrs (but does end with dot 2)
		elif [ "${TheDomain}" = "${TheDomain#??\.???\.}" ] ; then
			# the domain does end with dot 2 but is not dot 2 dot 2 nor dot 3 dot 2
			# chop the third segment of the domain if it exists (currently last segment because the domain is reversed)
			# for example: www.ecologia.unam.mx should become unam.mx
			# but www.news.com.au should become news.com.au
			# and riedam.lt should not be chopped
			 [ "${TheDomain}" != "${TheDomain#*\.*\.}" ] && TheDomain="${TheDomain%.*}"
		else
			# Here a domain ends in .3.2 like news.com.au which is fine, but not www.nic.mx which needs to lose the www. portion
			[ "${TheDomain}" != "${TheDomain%.www}" ] && TheDomain="${TheDomain%.*}"
		fi
	else
		# Here the domain does not end with 2 chrs so if there is a third segment, drop it
		[ "${TheDomain}" != "${TheDomain#*\.*\.}" ] && TheDomain="${TheDomain%.*}"
	fi

	# Reverse the now-trimmed and cleaned domain again so that it won't be backwards anymore
	TheDomain=$( echo "${TheDomain}" | rev )
fi

# Output the domain name, the command can be commented-out if not desired by pre-pending a "#"
echo "${red}DOMAIN:${normal} ${TheDomain}"

#-----------------------------------------------------------------------------#

# Prepare for whois

# Clear bash's internal field separator so that line breaks are ignored
IFS=''

# Get the whois output and convert ampersands to + and line endings to ampersands (so that we can try to create blocks of text instead of lines)
# Also add spaces following colons
AllText=$( whois "${TheDomain}" | tr '&' '+' | tr '\n' '&' | sed -f "${MyDir}/lists/sed_rules/RawWhoIsOutputFirstPass.txt" )

# Convert every instance of two consecutive ampersands in the whois output to a line ending
# This separates the blocks of output
AllText=$( echo "${AllText}" | sed -f "${MyDir}/lists/sed_rules/ExtraLineEndings.txt" )
AllText="${AllText//\&\&/${newline}}"

# Set bash's internal field separator to newline so line endings work again
IFS="${newline}"

# Create an array with each block of text in its own cell
TextBlocks=( ${AllText} )

# If this results in too few text blocks then likely the whois output does not have blank lines between sections and we'll have to do line mode
if [ ${#TextBlocks[*]} -lt 5 ] ; then
	AllText="${AllText//\&/${newline}}"
	TextBlocks=( ${AllText} )
	Mode="Lines"
fi

# Uppercase the domain for use in filtering later
TheDomain=$( echo "${TheDomain}" | tr "a-z" "A-Z" )

#-----------------------------------------------------------------------------#

# Loop through each array cell
for ((i=0;i<${#TextBlocks[*]};i++)) ; do

	# If we are in block mode not line mode and verbose mode is on then output a yellow line of dashes and the block number.
	[ "${Mode}" = "Blocks" ] && [ "${Verbose}" = "yes" ] && echo "${yellow}--------------------Block ${i}${normal}"

	# If the block is empty, skip it
	[ "${TextBlocks[${i}]}" = "" ] && continue

	# IF the block is essentially a blank line (an ampersand since we converted newlines to ampersands), then skip it.
	[ "${TextBlocks[${i}]}" = '&' ] && continue

	# Reset the flag for alternate output
	AlternateOutput="no"


	# Here, determine whether the current block should use alternate output
	# Careful when moving and inserting, the order matters.
	# For example the line "bob smith", if starts with "bob" then yes, if contains "smith" then no
	# You must determine which should override the other and place them in the necessary order within the script


	if [ "${Mode}" = "Blocks" ] ; then

		# If the block does not begin with a space or right angle bracket and mode is Blocks then yes
		if [ "${TextBlocks[${i}]:0:1}" != " " ] ; then
			[ "${TextBlocks[${i}]:0:1}" != ">" ] && AlternateOutput="yes"
		fi

		# Except if the block contains a colon (as in "Domain Name: testsite.net")
		[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]/\:/}" ] && AlternateOutput="no"

		# Except if the block contains period period (as in "Tech Contact........ Bob@whome.com")
		[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]/../}" ] && AlternateOutput="no"

		# Unless the block contains "type:  help" or "available at:" because it seems like good info to keep in the output
		[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]/type\:  help/}" ] && AlternateOutput="yes"
		[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]/available at\:/}" ] && AlternateOutput="yes"

		# Remove everything in the block after "Note:" because it's all crap, every time.
		TextBlocks[${i}]="${TextBlocks[${i}]%Note:*}"

	else	# If Mode is Lines

		# If the line does not contain a colon then yes
		[ "${TextBlocks[${i}]}" = "${TextBlocks[${i}]/\:/}" ] && AlternateOutput="yes"

		# Unless the line begins with a left square bracket (some whois output contain lines such as [Admin Contact] as a label regarding subsequent lines of info)
		[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]#\[}" ] && AlternateOutput="no"

		# If the line is longer than 80 characters then yes (because that's always crap.)
		[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]:0:80}" ] && AlternateOutput="yes"

		# If this line ends with colon and the next line contains a colon, then flag this one for alt output
		# Mostly for cases such as a long list of fields when only a few are populated (DNS1: DNS2: DNS3: ... DNS45: etc.)
		if [ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]%\:}" ] ; then
			[ "${TextBlocks[$(( ${i} + 1 ))]}" != "${TextBlocks[$(( ${i} + 1 ))]/\:/}" ] && AlternateOutput="yes"
		fi
	fi

	# If the block does begin with space-space-space-hyphen then yes
	[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]#\ \ \ \-}" ] && AlternateOutput="yes"

	# If the block begins with a lower case letter then yes
	[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]#[a-z]}" ] && AlternateOutput="yes"

	# If block contains ... then flag it for alternate output
	# This uses the "CrapContains.txt" list file from the horton/lists/exclude folder
	# Note the order these sections that use the lists are in and that the first one that matches does a continue 1 so that particular block will -never- be checked against the other lists!
	for ((j=0;j<${#List_CrapContains[*]};j++)) ; do
		[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]/${List_CrapContains[${j}]}/}" ] && AlternateOutput="yes" && continue 1
	done

	# If block is ... then flag it for alternate output
	# This uses the "CrapIs.txt" list file from the horton/lists/exclude folder
	for ((j=0;j<${#List_CrapIs[*]};j++)) ; do
		[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]/${List_CrapIs[${j}]}/}" ] && AlternateOutput="yes" && continue 1
	done

	# If block starts with ... then flag it for alternate output
	# This uses the "CrapStartsWith.txt" list file from the horton/lists/exclude folder
	for ((j=0;j<${#List_CrapStartsWith[*]};j++)) ; do
		[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]#${List_CrapStartsWith[${j}]}}" ] && AlternateOutput="yes" && continue 1
	done

	# If block starts with ... then DON'T flag it for alternate output
	# This uses the "GoodStuffStartsWith.txt" list file from the horton/lists/include folder
	for ((j=0;j<${#List_GoodStuffStartsWith[*]};j++)) ; do
		[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]#${List_GoodStuffStartsWith[${j}]}}" ] && AlternateOutput="no" && continue 1
	done

	# If block contains ... then no
	# The first group of lines here use a variable so not in text file list
	# TheDomain has been uppercased for this purpose
	[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]/${TheDomain}.*${TheDomain}}" ] && AlternateOutput="no"
	[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]/Domain Name:  ${TheDomain}}" ] && AlternateOutput="no"
	[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]/Domain name:  ${TheDomain}}" ] && AlternateOutput="no"
	# This uses the "GoodStuffContains.txt" list file from the horton/lists/include folder
	for ((j=0;j<${#List_GoodStuffContains[*]};j++)) ; do
		[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]/${List_GoodStuffContains[${j}]}/}" ] && AlternateOutput="no" && continue 1
	done

	# Output
	if [ "${AlternateOutput}" = "no" ] ; then
		# Output a blank line before each block of primary output
		[ "${Mode}" = "Blocks" ] && echo

		# Output the block to terminal using primary output method and convert ampersands to newlines as it's sent to output
		echo "${TextBlocks[${i}]//\&/${newline}}"

		# Also add the block to the final output (to send to TextEdit if running on a Mac OS X system)
		FinalOutput="${FinalOutput}${TextBlocks[${i}]//\&/${newline}}${newline}"

		# If there are ampersands in the block, add an extra newline to final output
		[ "${TextBlocks[${i}]}" != "${TextBlocks[${i}]/\&/}" ] && FinalOutput="${FinalOutput}${newline}"
	else
		# If verbose mode not enabled then skip output of filtered stuff
		[ "${Verbose}" = "no" ] && continue

		# Output the block using alternate output method
		echo "${cyan}${TextBlocks[${i}]//\&/ }${normal}"
	fi

done

# Add a blank line at the end of the output to terminal
echo

# Added this as a quick fix for chezmaman.be which has no whois output whatsoever, not one byte and no error. Nifty.
[ "${FinalOutput}" = "" ] && exit 0

# If final output does not contain "To single out one record" (suppresses this output feature when whois does not return desired results.)
if [ "${FinalOutput}" = "${FinalOutput/To single out one record/}" ] ; then
	# If final output does not contain "No match for" (suppresses this output feature when whois does not return desired results.)
	if [ "${FinalOutput}" = "${FinalOutput/No match for/}" ] ; then	
		# If we are running on a Mac OS X system, send final primary output to a new TextEdit document window, also remove leading spaces and squeeze spaces
		[ "${OSTYPE:0:6}" = "darwin" ] && echo "${FinalOutput}" | sed -e 's/^ *//g' -e 's/ {1,99}/ /g' | open -f TextEdit
	fi
fi

exit 0
