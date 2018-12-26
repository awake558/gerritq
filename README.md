# gerritq

可在gerrit快速添加走读人员

## 说明

1. 更换脚本中awake为自己gerrit账户名
2. 增加走读人员 可在-a 参数后添加

## 如何使用

### add reviewer

代码push后，运行 gerritq.sh –a ID

例如，这个 http://10.1.11.35:8081/739 提交 ,运行 gerritq.sh –a http://10.1.11.35:8081/739 就可以了

### code review

运行 gerritq.sh –r

会将需要自己review的提交全部 +1

### code marge

需要你自己添加

