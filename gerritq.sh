#!/bin/bash
#
#	echo "可在gerrit快速添加走读人员"
#	echo ""
#	echo "说明"
#	echo "1.	更换脚本中awake为自己gerrit账户名"
#	echo "2.	增加走读人员 可在-a 参数后添加"
#	echo ""
#	echo "代码push后，运行 gerritq.sh –a ID"
#	echo "例如，这个 http://10.1.11.35:8081/739 提交 ,运行 gerritq.sh –a http://10.1.11.35:8081/739 就可以了"
#
#	awake5588@qq.com  2015-5
#					  2017-9-1 
#


zhtdebug="zhtdebug"
echo_debug()
{
	if [ "$zhtdebug" = "zhtdebug" ] ; then 
		echo $*
	fi
}

IP_LIST="10.1.11.35 10.1.11.36"

USE() {


	echo -e "\n `basename $0`    gerrit quick code-review and merge"
	echo " awake558@qq.com"
	echo " "
	echo " USE `basename $0` [-lqarmgtsh]"
	echo " -l: List all reviewing code."
	echo " -lq: List quick reviewing code."
	echo " -a: add reviewers."
	echo " -r: gerrit review --code-review ; +1 ."
	echo " -m: "
	echo "     --mail:  send remander email for code merge"
	echo " -g: -m xxxx -g PROJECT"
	echo " -t: -m xxxx -t xxx@xxxx.com"
	echo " -s: subject"
	echo " -h: display help information."
	echo " "
	echo "`basename $0` –a http://10.1.11.35:8081/739"
	echo "`basename $0` -m http://10.3.11.35:8080/36008/ "
	echo "`basename $0` -m http://10.3.11.35:8080/36008/ -g PROJECT -t xxxxxx@xxxx.com -s 测试"

	exit 0
}

LIST() {

	for ip in `echo $IP_LIST`
	do
		echo_debug "LIST() ip = $ip"
		ssh -p 29418 $ip gerrit query status:open reviewer:self
	done

	exit 0
}
LIST--all-approvals() {

	for ip in `echo $IP_LIST`
	do
		echo_debug "LIST--all-approvals() ip = $ip"
		IDs=`ssh -p 29418 $ip gerrit query status:open reviewer:self | grep url | egrep "\/[0-9]+$" -o | sed -r 's/\///g'`
		for i in $IDs
		do
			echo_debug "$i  $ip --------------------------------------------------------------------------------------"
			ssh -p 29418 $ip  gerrit query $i --all-approvals
		done
	done
}

LIST-patch () {

	# 别人的patch看不到，gerrit -r +1 +2 才可以看得见
	LIST--all-approvals | egrep "revision:|project:"

}


Reviewers(){

	echo_debug "Reviewers()"
	echo_debug $1 $2

	ssh -p 29418 $1 gerrit set-reviewers -a zhangsan -a lisi -a wangwu  $2

	exit 0
}

Review() {

	for ip in `echo $IP_LIST`
	do
		echo_debug "Review() ip = $ip"

		list=`ssh -p 29418 $ip gerrit query reviewer:self status:open | grep number: | cut -d ":" -f 2`
		echo_debug $list
		for COMMIT in $list
		do
			PATCHSET=`ssh -p 29418 $ip gerrit query change:$COMMIT  --patch-sets  | grep number: | cut -d ":" -f 2 | tail -n 1`
			PATCHSET2=`echo $PATCHSET | cut -d " " -f 2`
			echo $COMMIT,$PATCHSET2
			ssh -p 29418 $ip gerrit review --code-review +1 $COMMIT,$PATCHSET2
		done
	done
}

send_mail()
{
	echo_debug "send mail ... "
	echo_debug $1 $2
	ssh -p 29418 $1 gerrit query $2 --all-approvals > ~/Mail/mail_$1_$2

	COMMIT=`grep revision ~/Mail/mail_$1_$2  | tail -n 1 | xargs -n 1 | tail -n 1`
	echo_debug "COMMIT = $COMMIT"
	#BRANCH=`grep branch ~/Mail/mail_$1_$2 | cut -d ":" -f 2`
	BRANCH=`grep branch ~/Mail/mail_$1_$2 | xargs -n 1 | tail -n 1`
	echo_debug "BRANCH = $BRANCH"
	URL=$1
	echo_debug "URL = $URL"

	GIT_LOCAL=`grep $URL ~/bin2/code.branch  | grep repo | cut -d ":" -f 6 | uniq`
	echo_debug "GIT_LOCAL = $GIT_LOCAL"

	REPO=`grep project ~/Mail/mail_$1_$2  | cut -d "/" -f 3`
	echo_debug "REPO = $REPO"

	ALL_PROJECT=`grep $BRANCH ~/bin2/code.branch | grep "branch_" | sed s/\|//g | cut -d ":" -f 1`
	echo_debug "ALL_PROJECT = $ALL_PROJECT"

	if [ "$PRO" = "PRO" ] ; then 
		ALL_RG_PROJECT=`echo $ALL_PROJECT | xargs -n 1 | grep $PRO_RG`
	else
		ALL_RG_PROJECT=$ALL_PROJECT
	fi
	echo_debug "ALL_RG_PROJECT = $ALL_RG_PROJECT"

	for PROJECT in $ALL_RG_PROJECT
	do
		echo_debug "PROJECT = $PROJECT"
		
		echo_debug "$GIT_LOCAL/yulong/$REPO"
		cd $GIT_LOCAL/yulong/$REPO
		git checkout master -f
		git branch -D $BRANCH
		git pull
		git checkout $BRANCH

		git show $COMMIT > ~/Mail/mail_$COMMIT.patch
		#sed -i s/@@/##/g   ~/Mail/mail_$COMMIT.patch

		MAIL_ADDRESS="-t "
		MAIL_ADDRESS=$MAIL_ADDRESS`cat /home/awake/Mail/mail_$COMMIT.patch | grep Author | grep "<.*>" -o | sed s/\<//g | sed s/\>//`
		echo_debug "MAIL_ADDRESS = $MAIL_ADDRESS"

		MAIL_ADDRESS="$MAIL_ADDRESS $ADDRESS"
		echo_debug "MAIL_ADDRESS = $MAIL_ADDRESS"

		echo_debug $PROJECT"_"$COMMIT.sh

		echo "#!/bin/bash" > ~/Mail/$PROJECT"_"$COMMIT.sh
		echo "res=\`find_commit_tag.sh -p $PROJECT -r $REPO -b $BRANCH -c $COMMIT\`" >> ~/Mail/$PROJECT"_"$COMMIT.sh
		echo "if [ \"\`echo \$res | grep success -o\`\" = \"success\" ] ; then" >> ~/Mail/$PROJECT"_"$COMMIT.sh

		#echo "echo \$res | xargs -n 1> ~/Mail/Mail.eml" >> ~/Mail/$PROJECT"_"$COMMIT.sh
		echo "echo \$res | tr \" \" \"\n\" > ~/Mail/Mail.eml" >> ~/Mail/$PROJECT"_"$COMMIT.sh
		echo "echo  >> ~/Mail/Mail.eml" >> ~/Mail/$PROJECT"_"$COMMIT.sh
		echo "echo  >> ~/Mail/Mail.eml" >> ~/Mail/$PROJECT"_"$COMMIT.sh

		echo "cat /home/awake/Mail/mail_$COMMIT.patch >> ~/Mail/Mail.eml " >> ~/Mail/$PROJECT"_"$COMMIT.sh
		#echo "send_mail.sh -s \" git提醒邮件: 请验证版本 $SUBJECT \" $MAIL_ADDRESS" >> ~/Mail/$PROJECT"_"$COMMIT.sh
		echo "send_mail.sh -s \" git提醒邮件: 请验证版本 $SUBJECT \" $MAIL_ADDRESS -a mail_$COMMIT.patch" >> ~/Mail/$PROJECT"_"$COMMIT.sh
		echo "rm ~/Mail/mail_$COMMIT.patch" >> ~/Mail/$PROJECT"_"$COMMIT.sh
		echo "else" >> ~/Mail/$PROJECT"_"$COMMIT.sh
		echo "at -f /home/awake/Mail/$PROJECT"_"$COMMIT.sh now + 1 minutes" >> ~/Mail/$PROJECT"_"$COMMIT.sh
		echo "fi" >> ~/Mail/$PROJECT"_"$COMMIT.sh

		at -f /home/awake/Mail/$PROJECT"_"$COMMIT.sh now + 1 minutes

	done
	exit
}

URL_ID()
{
	URL=`echo $1 | grep "//.*:" -o | sed s#/##g | sed s/://g | sed s/16/61/g`
	echo_debug "URL = $URL"
	echo_debug "\$1 = $1"
	if [ "`echo $1 | grep '#' -o`" = "#" ] 
	then
		echo_debug "#"
		ID=`echo $1 | grep ":[^/].*" -o | cut -d "/" -f 4`
	else
		echo_debug "!#"
		ID=`echo $1 | grep ":[^/].*" -o | cut -d "/" -f 2`
	fi

	echo_debug "ID = $ID"
}


# main ######################################################

if [ $# = "0" ] 
then
	USE
	exit 0
fi

while :; do
	case $1 in
		-l) LIST="LIST";;
		-lq) LIST="LIST_QUICK";;
		-a) ADD_REVIEWERS="ADD_REVIEWERS";GERRIT_COMMIT=$2; shift;;
		-r) REVIEW="REVIEW"; shift;;
		-m) MAIL="MAIL";GERRIT_COMMIT=$2; shift;;
		-g) PRO="PRO";PRO_RG=$2; shift;;
		-t) ADDRESS=$ADDRESS" -t "$2" "; shift;;
		-s) SUBJECT=$2; shift;;
		-h*) USE;;
		-?*) USE;;
	   --h*) USE;;
		*) break;;
	esac
	shift
done

echo_debug "LIST = $LIST"
echo_debug "ADD_REVIEWERS = $ADD_REVIEWERS"
echo_debug "MAIL = $MAIL"
echo_debug "GERRIT_COMMIT = $GERRIT_COMMIT"
echo_debug "PRO = $PRO"
echo_debug "PRO_RG = $PRO_RG"
echo_debug "ADDRESS = $ADDRESS"
echo_debug "SUBJECT = $SUBJECT"
echo_debug ""


if [ "$LIST" = "LIST" ] ; then 
	#LIST
	LIST--all-approvals
	#LIST-patch
fi

if [ "$LIST" = "LIST_QUICK" ] ; then 
	LIST--all-approvals |  egrep "change\ |project:|branch:|subject:|\ name:|-----"
fi

if [ "$ADD_REVIEWERS" = "ADD_REVIEWERS" ] ; then 
	echo_debug " add reviewers ..."
	URL_ID $GERRIT_COMMIT
	Reviewers $URL $ID
fi

if [ "$REVIEW" = "REVIEW" ] ; then 
	Review $2
fi

if [ "$MAIL" = "MAIL" ] ; then 
	URL_ID $GERRIT_COMMIT
	send_mail $URL $ID
fi


