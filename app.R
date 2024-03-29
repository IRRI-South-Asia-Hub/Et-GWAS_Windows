packages = c("shiny","shinyjs","shinythemes","crayon","ggplot2",
                     "ggridges","dplyr","ggfortify","ggpubr",
                     "extrafont","data.table","stringr","CMplot",
                     "MASS","zip","tidyr","tidyverse","RColorBrewer")
package.check <- lapply(packages, FUN = function(x) {
  if (!require(x, character.only = TRUE)) {
    install.packages(x, dependencies = TRUE)
    library(x, character.only = TRUE)
  }
})

library(shiny)
library(shinyjs)
library(shinythemes)
library(crayon)
library(ggplot2)
library(ggridges)
library(dplyr)
library(ggfortify)
library(ggpubr)
library(extrafont)
library(data.table)
library(stringr)
library(CMplot)
library(MASS)
library(zip)
library(tidyr)
library(tidyverse)
library(RColorBrewer)

par(mar=c(1,1,1,1))

#setwd("/srv/shiny-server/pooled-GWAS/")
source("scirpts/theme_Publication.R")
source("scirpts/association_main.R")
#source("scirpts/haplo_pheno.R")

system("chmod 755 SOFTWARES_QC/plink-1.07-x86_64/plink")
system("chmod 755 SOFTWARES_QC/plink2")

#Function to extract the genomic data
extract_irisID <- function(trait, infile, perc){
  
  theme_cus <- theme(panel.background = element_blank(),panel.border=element_rect(fill=NA),
                     panel.grid.major = element_blank(),panel.grid.minor = element_blank(),
                     strip.background=element_blank(),axis.text.x=element_text(colour="black"),
                     axis.text.y=element_text(colour="black"),
                     axis.ticks=element_line(colour="black"),
                     plot.margin=unit(c(1,1,1,1),"line"),
                     legend.title = element_text(color = "black", size = 10),
                     legend.text = element_text(color = "red"),
                     legend.background = element_rect(fill = "lightgray"),
                     legend.key = element_rect(fill = "white", color = NA))
  phenofile <- infile
  # Step1: Phenotypic extract -----------------------------------------------
  
  outlist <- paste0(trait,"_list.txt")
  hist_plot <- paste0(trait,"_histogram.png")
  box_plot <- paste0(trait,"_boxplot.png")
  
  phe <- read.delim(infile, header = T)
  colnames(phe) <- c("Accessions","trait")
  
  box <- ggplot(phe) + aes(y = trait) +
    geom_boxplot(fill = "#0c4c8a") + theme_cus + xlab("") + ylab(trait)
  ggsave(box, filename = paste0("www/",box_plot),width = 10,height = 6)
  
  his <- ggplot(data = phe, aes(x = trait)) + geom_histogram()+
    theme_cus + xlab("")
  
  ggsave(his,filename = paste0("www/",hist_plot),width = 10,height = 6)
  
  out1 <- phe[,c(1,1)]
  write.table(out1, file = outlist, col.names = F, row.names = F,
              quote = F)
  
  
  # Step 2: genotypic data extract------------------------------------------------
  infam <- paste0(trait,"_geno")
  system(paste0("SOFTWARES_QC/plink2 --bfile data/server2 --keep ",
                trait,"_list.txt --make-bed --out ",infam))
  
  system(paste0("SOFTWARES_QC/plink2 --bfile ",
                infam," --export ped --out ",infam))
  
  a <- read.delim(paste0(infam,".fam"), header = F,sep = "")
  names(a)[1:6] <- c("Fam_ID","Ind_ID","Paternal","Maternal","Sex","Phenotype")
  b <- phe
  names(b) <- c("IRIS.ID","Phenotype")
  comb <- merge(a,b, by.x = "Ind_ID", by.y = "IRIS.ID", all = F)
  comb$Phenotype.x <- comb$Phenotype.y
  out <- comb[!is.na(comb$Fam_ID),]
  out <- out[,c(1:6)]
  out$Paternal <- 0
  out$Maternal <- 0
  out$Sex <- 0
  out$Phenotype.x[is.na(out$Phenotype.x)] <- -9
  
  write.table(out, file = paste0(infam,".fam"), col.names = F, row.names = F,
              quote = F, sep = " ")
  remove(out)


# pca_plink ---------------------------------------------------------------
  pheno <- "data/IRIS_pop_all.txt"
  theme_cus <-theme(panel.background = element_blank(),panel.border=element_rect(fill=NA),
                    panel.grid.major = element_blank(),panel.grid.minor = element_blank(),
                    strip.background=element_blank(),
                    axis.text.y=element_text(colour="black", face = "bold"),
                    axis.text.x=element_text(colour="black", face = "bold",angle = 90),
                    axis.ticks=element_line(colour="black"),
                    strip.text.x = element_text(colour="black", face = "bold"),
                    title = element_text(color = "black", size = 12,
                                         face = "bold"),
                    plot.margin=unit(c(1,1,1,1),"line"),
                    legend.title = element_text(color = "black", size = 12, 
                                                face = "bold"),
                    legend.text = element_text(colour = "black", size = 12,),
                    legend.key = element_rect(fill = "white", color = NA))
  
  
  infam2 <- infam
  
  system(paste0("SOFTWARES_QC/plink2 --bfile ",infam,
                " --pca 5 --nonfounders --out ",infam,"-pc"))
  
  pca_plot <- paste0(trait,"_pca.png")
  pov_plot <- paste0(trait, "_pov.png")
  
  
  #PLINK
  pca_file <- paste0(infam, "-pc.eigenvec")
  val_file <- paste0(infam, "-pc.eigenval")
  m <- read.table(pca_file, header = F)
  cat(blue(paste("Loading",pca_file,"...\n")))
  names(m)[1:5] <- c("FID","IID","PC1","PC2","PC3")
  
  phe <- read.delim(pheno, header = T)
  cat(blue(paste("Loading",pheno,"...\n")))
  names(phe) <- c("Name","IRIS.ID","SUBPOPULATION","COUNTRY")
  
  comb_p <- merge(m, phe, by.x = "FID", by.y = "IRIS.ID", all.x = T)
  
  p1 <- ggplot(comb_p) + geom_point(aes(x=PC1,y=PC2, color=SUBPOPULATION)) +
    theme_cus + theme(legend.position = "none")+
    scale_color_manual(breaks = c("indx","ind2","ind1B","ind1A","ind3",
                                  "aus","japx","temp",
                                  "trop","subtrop","admix","aro" ),
                       values = c( "#56B4E9", "#56B4E9","#0072B2", "#293352",
                                   "#00AFBB", "#000000", "#E69F00","#F0E442",
                                   "#D55E00", "#CC79A7","#999999", "#52854C"))
  p1 <- p1 + theme_Publication()
  
  ggsave(paste0(trait,"_pca.jpeg"), p1, width = 8, height = 8)
  
  p2 <- ggplot(comb_p) + geom_point(aes(x=PC1,y=PC3, color=SUBPOPULATION)) +
    theme_cus + theme(legend.position = "none")+
    scale_color_manual(breaks = c("indx","ind2","ind1B","ind1A","ind3",
                                  "aus","japx","temp",
                                  "trop","subtrop","admix","aro" ),
                       values = c( "#56B4E9", "#56B4E9","#0072B2", "#293352",
                                   "#00AFBB", "#000000", "#E69F00","#F0E442",
                                   "#D55E00", "#CC79A7","#999999", "#52854C"))
  p3 <- ggplot(comb_p) + geom_point(aes(x=PC2,y=PC3, color=SUBPOPULATION)) +
    theme_cus + theme(legend.position = "none")+
    scale_color_manual(breaks = c("indx","ind2","ind1B","ind1A","ind3",
                                  "aus","japx","temp",
                                  "trop","subtrop","admix","aro" ),
                       values = c( "#56B4E9", "#56B4E9","#0072B2", "#293352","#00AFBB",
                                   "#000000", "#E69F00","#F0E442",
                                   "#D55E00", "#CC79A7","#999999", "#52854C"))
  
  ar <- ggarrange(p1,ggarrange(p2,p3,labels = c("B", "C"),ncol = 2,nrow = 1),
                  ncol = 1,nrow = 2,labels = "A", 
                  common.legend = T, legend = "bottom")
  print(ar)
  cat(green(paste0("Saving PCA plot for first 4 components in ",pca_plot, "...\n")))
  ggsave(pca_plot, ar, width = 8, height = 6)
  
  value <- read.table(val_file, header = F)
  var <- (value/sum(value))*100
  var$V2 <- c(1:nrow(value))
  
  pov <- ggplot(var) + geom_line(aes(x = V2, y = V1), color="red") +
    geom_point(aes(x = V2, y = V1),shape = 8) + 
    theme_cus + xlab("Principal Components") + ylab("PoV")
  
  cat(green(paste0("Saving PCA PoV of first 4 components in pca_pov.pdf", 
                   pov_plot,"...\n")))
  ggsave(pov_plot, pov, width = 8, height = 6)

# pheno_dist_xp -----------------------------------------------------------
  cat(green("Pheno_dist\n"))
  
  popfile <- "data/IRIS_pop_all.txt"
    
  Type <- c("indx","ind2","aus","ind1B","ind1A",
            "ind3","japx","temp","trop","subtrop","admix","aro")
  
  # Initial distribution ----------------------------------------------------
  b <- read.delim(phenofile, header = T)
  names(b) <- c("Designation","phenotype")
  pop <- read.delim(popfile, header = T)
  names(pop) <- c("Name","Designation","Subpopulation","COUNTRY")
  
  val <- ceiling((perc*nrow(b))/100)
  
  bb <- merge(b, pop, by = "Designation", all = F)
  b <- bb[!is.na(bb$phenotype),]
  
  b$Type <- b$Subpopulation
  b$Type <- gsub(pattern = "indx",replacement = "ind",b$Type)
  b$Type <- gsub(pattern = "ind2",replacement = "ind",b$Type)
  b$Type <- gsub(pattern = "ind1B",replacement = "ind",b$Type)
  b$Type <- gsub(pattern = "ind1A",replacement = "ind",b$Type)
  b$Type <- gsub(pattern = "ind3",replacement = "ind",b$Type)
  
  low <- max(head(b[order(b$phenotype, decreasing=F), ], val)[,2])
  high <- min(head(b[order(b$phenotype, decreasing=T), ], val)[,2])
  
  b$group <- ifelse(b$phenotype <= low, 1, ifelse(b$phenotype >= high, 3, 2))
  supp.labs <- c("Low bulk", "Mixed","High bulk")
  names(supp.labs) <- c("1", "2", "3")
  
  image_file <- paste0(trait,"_",perc,"_dist1.png")
  #png(image_file, width = 1000, height = 650)
  dist <- ggplot(data=b, aes(phenotype)) + theme_bw() + 
    theme(legend.position="none",
          panel.background = element_blank(),panel.border=element_rect(fill=NA),
          panel.grid.major = element_blank(),panel.grid.minor = element_blank(),
          strip.background=element_blank(),
          panel.spacing = unit(0.3, "lines"),
          strip.text.x = element_text(size = 12),
          axis.title.y = element_blank(),
          axis.ticks = element_line(colour = "black"),
          axis.text.x=element_text(colour="black", size = 12),
          axis.text.y=element_text(colour="black", size = 12)) +
    geom_bar(data=subset(b,group==1),col="black", fill="red", 
             alpha = 0.5)+
    geom_bar(data=subset(b,group==2),col="black", fill="green", 
             alpha = 0.5) +
    geom_bar(data=subset(b,group==3),col="black", fill="blue", 
             alpha = 0.5, )+
    facet_grid(. ~ group, scales = "free", labeller = labeller(group = supp.labs))
  #dev.off()
  ggsave(image_file, dist, width = 8, height = 6)
  
  image_file <- paste0(trait,"_",perc,"_subdist1.png")
  #png(image_file, width = 1000, height = 650)
  dist2 <- ggplot(b, aes(x = phenotype, y = Subpopulation, fill=Subpopulation)) + 
    geom_density_ridges2(alpha=0.5)+
    xlab("Yield") +
    theme(legend.position="none",
          panel.background = element_blank(),panel.border=element_rect(fill=NA),
          panel.grid.major = element_blank(),panel.grid.minor = element_blank(),
          strip.background=element_blank(),
          panel.spacing = unit(0.3, "lines"),
          strip.text.x = element_text(size = 12),
          axis.title.y = element_blank(),
          axis.ticks = element_line(colour = "black"),
          axis.text.x=element_text(colour="black", size = 12),
          axis.text.y=element_text(colour="black", size = 12)) +
    geom_vline(xintercept = c(low,high),linetype="dashed", color = "red")
  #dev.off()
  ggsave(image_file, dist2, width = 8, height = 6)
  
  pheno_out <- paste0(trait,"_",perc,"_XPpheno.txt")
  write.table(b, file = pheno_out, sep = "\t", row.names = F, 
              col.names = T, quote = F)
  
  #Extra
  low <- b[b$group==1,c(1,1)]
  write.table(low, file = paste0(trait,"_low",perc,".txt"),
              sep = "\t", row.names = F, col.names = F, quote = F)
  
  high <- b[b$group==3,c(1,1)]
  write.table(high, file = paste0(trait,"_high",perc,".txt"),
              sep = "\t", row.names = F, col.names = F, quote = F)
  
  rand <- b[b$group==2,c(1,1)]
  rand2 <- rand[as.integer(runif(min(nrow(low),nrow(high)),1,nrow(rand))),]
  write.table(rand2, file = paste0(trait,"_rand",perc,".txt"),
              sep = "\t", row.names = F, col.names = F, quote = F)
  
  cat(green("Completed the pheno analysis\n"))
  

# Pooling genotype --------------------------------------------------------
  infam <- paste0(trait,"_geno")
  hmpfile <- paste0(infam,".hmp.txt")
  
  low_in <- paste0(trait,"_low",perc,".txt")
  rand_in <- paste0(trait,"_rand",perc,".txt")
  high_in <- paste0(trait,"_high",perc,".txt")
  
  low_out <- paste0(trait,"_low",perc)
  rand_out <- paste0(trait,"_rand",perc)
  high_out <- paste0(trait,"_high",perc)
  
  system(paste0("SOFTWARES_QC/plink2 --bfile ",
                infam," --keep ",low_in," --export ped --out ", low_out))
  system(paste0("SOFTWARES_QC/plink2 --bfile ",
                infam," --keep ",rand_in," --export ped --out ",rand_out))
  system(paste0("SOFTWARES_QC/plink2 --bfile ",
                infam," --keep ",high_in," --export ped --out ",high_out))
  
  system(paste0("SOFTWARES_QC/plink2 --bfile ",infam," --freq --out ",infam))
  
  system(paste0("bash scirpts/pooling_snp.sh -h ",infam))
  
  bulks <- c("high","low","rand")
  
  pooling_snp <- function(i){
    
    infile <- paste0(trait,"_",bulks[i],perc,".ped")
    c <- read.delim(infile, header = F, colClasses = c("character"))
    d <- c[,c(7:ncol(c))]
    out <- apply(d, 2, function(x){
      run = rle(sort(x[x!=0]))
      if(length(run$lengths) < 2){
        run$lengths[2] <- 0
        run$values[2] <- 0
      } 
      g <- stack(run)[1]
    })
    
    lstData <- Map(as.data.frame, out)
    dfrData <- rbindlist(lstData)
    
    count_cols <- sort(c(seq(1,nrow(dfrData),4),seq(2,nrow(dfrData),4)))
    all_cols <- sort(c(seq(3,nrow(dfrData),4),seq(4,nrow(dfrData),4)))
    df <- dfrData[count_cols]
    df$all <- dfrData[all_cols]
    
    colhead <- data.frame(rep(seq(1,(nrow(df)/4)), each=4))
    colnames(colhead) <- "num"
    
    comb <- cbind(colhead,df)
    comb$values <- as.numeric(comb$values)
    comb$alle <- paste(comb$num, comb$all, sep = "_")
    comb <- comb[comb$all != 0,]
    out <- comb %>% dplyr::group_by(alle) %>% 
      dplyr::summarize(tot = sum(values), nums = unique(num), .groups = 'drop')
    
    outfile <- paste0("temp_",bulks[i],".csv")
    write.csv(out, outfile, row.names = F)
  }

  result <- for(i in c(1:3)){
     pooling_snp(i)
  }

  out_low <- read.csv("temp_low.csv")
  out_high <- read.csv("temp_high.csv")
  out_rand <- read.csv("temp_rand.csv")
  
  temp <- merge(out_high,out_low, by = "alle", all = T)
  comb <- merge(temp,out_rand, by = "alle", all = T)
  out <- comb[order(comb$nums.x),c(1,2,4,6,7)]
  colnames(out) <- c("RefAlt", "high" ,"low","random","num")
  
  # Ref and Alt alleles From HapMap -----------------------------------------
  hmpfile <- paste0(infam,"_hmp_allele.txt")
  hmp <- read.delim(hmpfile,header = T,sep = "\t")
  hmp$num <- c(1:nrow(hmp))
  hmp$Ref1 <- paste(hmp$num,hmp$Ref,sep = "_")
  hmp$Alt1 <- paste(hmp$num,hmp$Alt,sep = "_")
  ref <- hmp[,c(3,4)]
  alt <- hmp[,c(3,5)]
  
  ref_comb <- merge(ref,out,by.x = "Ref1", by.y = "RefAlt")
  alt_comb <- merge(alt,out,by.x = "Alt1", by.y = "RefAlt")
  names(alt_comb)[3:5] <- c("high_alt","low_alt","random_alt")
  names(ref_comb)[3:5] <- c("high_ref","low_ref","random_ref")
  
  comb <- merge(ref_comb,alt_comb, by = "num.x", all = T)
  final <- comb[,c(2,7,3,8,4,9,5,10)]
  colnames(final) <- c("Ref","Alt","high_ref","high_alt","low_ref",
                       "low_alt","random_ref","random_alt")
  
  final_out <- paste0(trait,"_pgwas_input",perc,".txt")
  write.table(final, file = final_out, sep = "\t",col.names = T, row.names = F,
              quote = F)
  print("the input file has been created")
  
# Association -------------------------------------------------------------
  mapfile <- paste0(trait,"_geno.map")
  
  outfile <- paste(trait,"_pgwas_out",perc,".txt",sep = "")
  outqtls <- paste(trait,"_qtls",perc,".txt",sep = "")
  outsnps <- paste(trait,"_snp",perc,".txt",sep = "")
  
  input <- final
  input[is.na(input)]=0
  
  cols = c(3:8)    
  input[,cols] = apply(input[,cols], 2, function(x) as.numeric(as.character(x)));
  map <- read.delim(mapfile, header = F)
  input2 <- cbind(map[,c(2,1,4)],input[,c(3:8)])
  input <- input2
  names(input)[1] <- "snpid"
  names(input)[2] <- "chr"
  names(input)[3] <- "pos"
  
  remove(final)
  xpgwas_modified <- function(input, filter=50,  plotlambda=TRUE){
    statout <- get_chistat(snps=input, filter=filter)
    
    lam <- estlambda(statout$stat, plot = plotlambda, proportion = 1, 
                     method = "regression",
                     filter = TRUE, main="Before genomic control")
    
    outqval <- xpgwas_qval(stat=statout, lambda=lam[['estimate']])
    return(outqval)  
  }
  
   qval <- xpgwas_modified(input, filter=50,  plotlambda=TRUE)
   
   b <- qval[,c(1:3,5)]
   names(b) <- c("SNP","Chromosome","Position","trait1")
   
   CMplot(b,plot.type="m",threshold=c(0.01,0.05)/nrow(b),
          threshold.col=c('red','orange'),
          multracks=FALSE, chr.den.col=NULL,
          file.name = paste0(trait,"_",perc),
          file="jpg",dpi=600,file.output=TRUE,verbose=TRUE,width=10,height=10)
   
   write.table(qval, file = outfile, col.names = T, row.names = F, 
               quote = F,sep = "\t")
  

   #xpplot_mine
   
   # Findign significant snps ------------------------------------------------
   suggestiveline = -log10(5e-05)
   genomewideline = -log10(5e-08)
  
   qval$log10p <- -log10(qval$pval)
   SNPset <- qval
   qtltable <- SNPset[SNPset$log10p >= suggestiveline,]
   write.table(qtltable$snpid, file = outsnps, col.names = F, row.names = F, 
               quote = F, sep = "\t")
  
  
   qtltable <- SNPset %>% dplyr::mutate(passThresh = log10p >= suggestiveline) %>%
     dplyr::group_by(chr, run = {
       run = rle(passThresh)
       rep(seq_along(run$lengths), run$lengths)
     }) %>% dplyr::filter(passThresh == TRUE) %>% dplyr::ungroup()
  
   if(nrow(qtltable) > 0){
     qtltable <- qtltable %>% dplyr::ungroup() %>% dplyr::group_by(chr) %>%
       dplyr::group_by(chr, qtl = {
         qtl = rep(seq_along(rle(run)$lengths), rle(run)$lengths)
       }) %>% dplyr::select(-run) %>%
       dplyr::summarize(start = min(pos), end = max(pos), length = end - start + 1,
                        nSNPs = length(pos),
                        avgSNPs_Mb = round(length(pos)/(max(pos) - min(pos)) * 1e+06),
                        .groups = 'drop')
   }
   names(qtltable)[1] <- "CHR"
   write.table(qtltable, file = outqtls, col.names = T, row.names = F, 
               quote = F, sep = "\t")
   print("everything is done")

  list(plot1 = box, plot2 = his,plot3 = ar, plot4 = pov, plot5 = dist,
       plot6 = dist2)
}


ui <- fluidPage(
  theme = shinytheme("flatly"),
  titlePanel("Et-GWAS"),
  sidebarLayout(
    sidebarPanel(
      selectInput(inputId = "Bulk_size",
                  label = "Bulk size:",
                  choices = c("10", "15", "20")),
      
      textInput("Trait", "Trait" , "Ex: SPY "),
      verbatimTextOutput("value"),
      
      fileInput("upload", "Phenotype"),
      
      actionButton("runButton", "Run"),
      
      downloadButton("downloadData", label = "Download")
      
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Phenotype", plotOutput("plot1", width = "100%", 
                                         height = "300px"),
                 plotOutput("plot2", width = "100%", height = "300px")),
        tabPanel("Population structure", plotOutput("plot3", width = "100%", 
                                                    height = "300px"),
                 plotOutput("plot4", width = "100%", height = "300px")),
        tabPanel("Phenotypic distribution", plotOutput("plot5", width = "100%", 
                                                       height = "300px"),
                 plotOutput("plot6", width = "100%", height = "300px")),
        tabPanel("Association", plotOutput("plot7", width = "100%", 
                                           height = "300px")))
    )
  )
)

server <- function(input, output, session) {
  
  plotData <- reactiveVal(NULL)
  processingResult <- reactiveVal(NULL)

  phe = reactive({
    phe <- read.csv(file = input$upload$datapath,header = T)
    return(phe)
  })
  
  observeEvent(input$runButton, {
    
    processingResult(NULL)  
    
    showModal( modalDialog(
      h4(paste0("Association analysis for ",nrow(phe())," genotypes")),
      footer=tagList(h3("running..."))
    ))
    
    plotData(extract_irisID(input$Trait,input$upload$datapath, as.numeric(input$Bulk_size)))
    processingResult()
    
    if(file.exists(file.path(paste(input$Trait,"_pgwas_out",as.numeric(input$Bulk_size),".txt",sep = "")))){
      removeModal()
      
      showModal(modalDialog(
        h4(paste0("Extreme trait association analysis is complete")),
        footer=tagList(actionButton("ok","Proceed to download the files"))
      ))
      
      observeEvent(input$ok, {
        removeModal()
      })
    }
  })

  output$resultText <- renderPrint({
    processingResult()
  })
  
  output$plot1 <- renderPlot({
    if (!is.null(plotData()))
      plotData()$plot1
  })
  output$plot2 <- renderPlot({
    if (!is.null(plotData()))
      plotData()$plot2
  })
  output$plot3 <- renderPlot({
    if (!is.null(plotData()))
      plotData()$plot3
  })
  output$plot4 <- renderPlot({
    if (!is.null(plotData()))
      plotData()$plot4
  })
  output$plot5 <- renderPlot({
    if (!is.null(plotData()))
      plotData()$plot5
  })
  output$plot6 <- renderPlot({
    if (!is.null(plotData()))
      plotData()$plot6
  })
  output$plot7 <- renderPlot({
    
    qval <- read.delim(paste(input$Trait,"_pgwas_out",as.numeric(input$Bulk_size),".txt",sep = ""))
    b <- qval[,c(1:3,5)]
    names(b) <- c("SNP","Chromosome","Position","trait1")
    
    CMplot(b,plot.type="m",threshold=c(1e-4,1e-6),
           threshold.col=c('red','orange'),
           multracks=FALSE, chr.den.col=NULL, file.output=FALSE)
  })
  
  output$downloadData <- downloadHandler(
    filename <- function() {
      paste("output", "zip", sep=".")
    },
    content <- function(file) {
      dir.create("out")
      system(paste0("cp ",input$Trait,"*.png ",
                    input$Trait,"*.jpeg ",
                    "*.jpg ",
                    input$Trait,"_pgwas* ",
                    input$Trait,"*.pdf ",
                    "out"))
      files2zip <- dir('out', full.names = TRUE)
      zip(zipfile = 'testZip', files = files2zip)
      file.copy("testZip", file)
    },
    contentType = "application/zip"
  )
}

shinyApp(ui, server)
