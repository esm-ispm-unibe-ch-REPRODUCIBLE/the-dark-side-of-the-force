###############
#### model II ###
###############


##### some definitions
MAE=c()
bias=c()
SSresults=c()
difference.best.worst=c()
sd.best.worst=c()
D=list()
jags.m=list()
difference.best.reference=c()
sd.best.ref=c()
coverage=c()


#####################
#####################
model2=function() {
  
for(i in 1:NS){
dm[i]<-d[t2[i]]-d[t1[i]]
prec[i]<-1/(SE[i]*SE[i])
y[i]~dnorm(dm[i],prec[i])}
d[1]<-0
for(i in 2:NT){
d[i]~dnorm(md,sd)}
md~dnorm(0,0.1)
sd<-1/(td*td)
td~dunif(0,2)

for (i in 1:NT){
for (j in i:NT){
D[j,i]<-d[j]-d[i]}}

#TreatmeNT hierarchy
  order[1:NT]<- NT+1- rank(d[1:NT])
for(k in 1:NT) {
# this is when the outcome is positive - omit  'NT+1-' when the outcome is negative
most.effective[k]<-equals(order[k],1)
for(j in 1:NT) {
effectiveness[k,j]<- equals(order[k],j)}}
for(k in 1:NT) {
for(j in 1:NT) {
cumeffectiveness[k,j]<- sum(effectiveness[k,1:j])}}

#SUCRAS#
for(k in 1:NT) {
SUCRA[k]<- sum(cumeffectiveness[k,1:(NT-1)]) /(NT-1)}}

##############


params=c() 
for (i in 1:(N.treat-1)){
  for (j in (i+1):N.treat){
    params=c(params, paste("D[",j,",",i,"]",sep=""))
  }}
for (i in 2:(N.treat)){
  params=c(params, paste("d[",i,"]",sep=""))
}
for (i in 1:(N.treat)){
  params=c(params, paste("SUCRA[",i,"]",sep=""))
}

#number of D parameters
no.D=N.treat*(N.treat-1)/2

TE2=c(TE[9],TE[1:8])

for (i in 1:N.sim){
  #model1.spec<-textConnection(model1.string) 
  initialval = NULL
  data2 <- list(y = data1[[i]]$TE,SE=data1[[i]]$seTE, NS=length(data1[[i]]$studlab), t1=data1[[i]]$t1,t2=data1[[i]]$t2, NT=N.treat)
  
  jags.m[[i]] <- jags.parallel(data=data2,initialval,parameters.to.save = params, n.chains = 2, n.iter = 15000, n.thin=1, n.burnin = 5000, DIC=F, model.file = model2)
  print(i)
 
  ## bias and MAE of basic parameters  
  bias[i]=(mean(jags.m[[i]]$BUGSoutput$summary[(no.D+N.treat+1):(no.D+2*N.treat-1),1]-TE))
  MAE[i]=mean(abs(jags.m[[i]]$BUGSoutput$summary[(no.D+N.treat+1):(no.D+2*N.treat-1),1]-TE))
  
  ## best and worst treatment
  best.treat=which.max(jags.m[[i]]$BUGSoutput$summary[(no.D+1):(no.D+N.treat),1])
  best.treat=substr(names(best.treat),7,nchar(names(best.treat))-1)
  worst.treat=which.min(jags.m[[i]]$BUGSoutput$summary[(no.D+1):(no.D+N.treat),1])
  worst.treat=substr(names(worst.treat),7,nchar(names(worst.treat))-1)
  index1.difference.best.worst= (as.numeric(best.treat)>as.numeric(worst.treat))*which(rownames(jags.m[[i]]$BUGSoutput$summary)==paste("D[",best.treat,",",worst.treat,"]",sep=""))
  index2.difference.best.worst= (as.numeric(best.treat)<as.numeric(worst.treat))*which(rownames(jags.m[[i]]$BUGSoutput$summary)==paste("D[",worst.treat,",",best.treat,"]",sep=""))
  index.difference.best.worst=max(index1.difference.best.worst,index2.difference.best.worst)
  difference.best.worst[i]=abs(jags.m[[i]]$BUGSoutput$summary[index.difference.best.worst,1])
  sd.best.worst[i]=abs(jags.m[[i]]$BUGSoutput$summary[index.difference.best.worst,2])
   D[[i]]=jags.m[[i]]$BUGSoutput$summary[1:(N.treat*(N.treat-1)/2),c(3,7)]
  
  
  index.difference.best.ref=which(rownames(jags.m[[i]]$BUGSoutput$summary)==paste("D[",best.treat,",",1,"]",sep=""))
 if(length(index.difference.best.ref)!=0){
    difference.best.reference[i]=abs(jags.m[[i]]$BUGSoutput$summary[index.difference.best.ref,1])
    sd.best.ref[i]=(jags.m[[i]]$BUGSoutput$summary[index.difference.best.ref,2])} else {
      difference.best.reference[i]=0
      sd.best.ref[i]=0    }
  coverage[i]=(mean(jags.m[[i]]$BUGSoutput$summary[(no.D+N.treat+1):(no.D+2*N.treat-1),3]<TE2&jags.m[[i]]$BUGSoutput$summary[(no.D+N.treat+1):(no.D+2*N.treat-1),7]>TE2))
  
  
  ## delete jags from memory
  jags.m[[i]]=NULL 
} 







