if(!requireNamespace("ggplot2")) install.packages("ggplot2")
library(ggplot2)
args<-commandArgs(T)
# CDR3 sequence length
len_data <- read.table(paste0("7.geneUsage/",args[1],".CDR3.length_percent.txt"),header=T,sep='\t')
g <- ggplot(len_data,aes(x=as.numeric(CDR3_nu_len),y=frequency*100))+labs(x="length",y="percent",title = "CDR3 Length")+geom_bar(stat='identity',fill="cyan3")+
scale_x_continuous(limits = c(15,75),breaks=seq(15,75,3))
ggsave(paste0("9.visualization/",args[1],".CDR3_nucl_len.png"),g,height = 3, width = 5)
# CDR3 amino acid percentage
data <-read.table(paste0("7.geneUsage/",args[1],".top10_CDR3_AA.percent.txt"),header=T,sep='\t')
g <- ggplot(data,aes(x=factor(as.numeric(rownames(data))),y=frequency*100))+geom_bar(stat="identity",fill="cyan3")+labs(x="clonetype",y="Frequency(%)",title = "Top10 CDR3 AA")
ggsave(paste0("9.visualization/",args[1],".CDR3_aa_top10.png"),g,height = 3, width = 5)

data <- read.table(paste0("7.geneUsage/",args[1],".xls"),header=T,sep='\t')
g <- ggplot(data,aes(x=as.numeric(rownames(data)),y=log(cloneCount,10)))+geom_line()+labs(x="clone_number",y="log10(clone_count)",title="Abundance Distribution")
ggsave(paste0("9.visualization/",args[1],".CDR3_abundance.png"),g,height = 3, width = 5)

data <- read.table(paste0("7.geneUsage/",args[1],".V_count.hist.percent"),header=T,sep='\t')
g <- ggplot(data,aes(x=factor(V_gene),y=frequency*100))+geom_bar(stat='identity',fill="cyan3")+labs(x="V Gene",y="percent(%)",title="V gene Usage")+
theme(axis.text.x=element_text(family="myFont",face="bold",size=6,angle=90))
ggsave(paste0("9.visualization/",args[1],".V_gene_usage.png"),g,height = 3, width = 6)

data  <- read.table(paste0("7.geneUsage/",args[1],".J_count.hist.percent"),header=T,sep='\t')
g <- ggplot(data,aes(x=factor(J_gene),y=frequency*100))+geom_bar(stat='identity',fill="cyan3")+labs(x="J Gene",y="percent(%)",title="J gene Usage")+
theme(axis.text.x=element_text(family="myFont",face="bold",size=9,angle=90))
ggsave(paste0("9.visualization/",args[1],".J_gene_usage.png"),g,height = 3, width = 6)

data <- read.table(paste0("6.vdj/",args[1],'.vdj_len.txt'),header=T,sep="\t")
p <- ggplot(data,aes(x=length,y=percentage,fill=gene))+geom_bar(stat='identity',position='dodge')+labs(title="V(D)J gene length")+
scale_x_continuous(breaks=seq(-5,45,5))
ggsave(paste0("9.visualization/",args[1],".vdj_length.png"),p,height = 3, width = 5)

data <- read.table(paste0("6.vdj/",args[1],'.vdj_del.txt'),header=T,sep="\t")
p <- ggplot(data,aes(x=length,y=percentage,fill=deletion))+geom_bar(stat='identity',position='dodge')+labs(title="V(D)J deletion length")+
scale_x_continuous(breaks=seq(-27,21,3))
ggsave(paste0("9.visualization/",args[1],".vdj_deletion.png"),p,height = 3, width = 5)

data <- read.table(paste0("6.vdj/",args[1],'.vdj_junc.txt'),header=T,sep="\t")
p <- ggplot(data,aes(x=length,y=percentage,fill=gene))+geom_bar(stat='identity',position='dodge')+labs(title="V(D)J junction length")+
scale_x_continuous(limits = c(-5,35),breaks=seq(-5,35,2))
ggsave(paste0("9.visualization/",args[1],".vdj_junction.png"),p,height = 3, width = 5)

if(!requireNamespace("reshape2")) install.packages("reshape2")
library(reshape2)
a <- read.table(paste0("6.vdj/",args[1],'.V_J_count_3D'),header=T,sep="\t")
tmp=dcast(a,V_gene~J_gene)
tmp[is.na(tmp)]<-0
data=as.matrix(tmp[,-1])
rownames(data)=tmp[,1]
write.table(data, file = paste0("7.geneUsage/",args[1], ".V_J_gene_Usage_3D.txt"),sep = "\t")
## library(ggplot2)
## heatmap(data,col = cm.colors(256), scale = "row")

if(!requireNamespace("gplots")) install.packages("gplots")
library(gplots)
pdf(file=paste0("9.visualization/",args[1],".VJ_usage_3D.pdf"))
heatmap.2(data,col=bluered(100),scale="row",trace="none",Rowv=F,Colv=F,key=T,keysize=1.5,cexCol=1,cexRow=0.7)
dev.off()
