#!/bin/bash
BPATH=`pwd`
MOD=`basename "$BPATH"`
#echo `dirname "$BPATH"`

if [ "$#" == 0 ] ; then
 echo "choose a target file. EXIT"
 exit 1 
else 
 if [ ! -f $1.bak ] ; then  cp $1 $1.bak ; fi
 NAME=$1
 BNAME=`echo "osnailyfacter::"${MOD//-/_}::${NAME//-/_}|rev|cut -d"." -f 2| rev `
 CNAME="class $BNAME {"
 INCL="include ::$BNAME"
 echo MODULE: $MOD
 echo FILENAME: $NAME
 echo CLASSNAME: $CNAME
 echo INCLUDE: $INCL
fi

#create NEW dir in "manifests"
DIRN='/etc/puppet/modules/osnailyfacter/manifests/'${MOD}
mkdir -p $DIRN

if [ ! -d $DIRN ] ; then
 echo "Wrong directory. EXIT"
 exit 1
fi

#SHIFT to right all the lines
sed 's/^/  /' -i $NAME
sed 's/^  $//' -i $NAME

#ADD 1ST and LAST lines
sed "1i ${CNAME}\n" -i $NAME
echo "}" >> $NAME 

# copy wrapped manifest
echo "cp /etc/puppet/modules/osnailyfacter/modular/$MOD/$NAME /etc/puppet/modules/osnailyfacter/manifests/${MOD//-/_}/${NAME//-/_}"
cp /etc/puppet/modules/osnailyfacter/modular/$MOD/$NAME /etc/puppet/modules/osnailyfacter/manifests/${MOD//-/_}/${NAME//-/_}

#change all the content to one line include
echo $INCL > /etc/puppet/modules/osnailyfacter/modular/$MOD/$NAME


echo -e "\n..done"
exit 1

