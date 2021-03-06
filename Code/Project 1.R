setwd("~/Documents/GitHub/RProjectsVL/")
getwd()

pkgs <- c("scales","car","RColorBrewer",
          "scatterplot3d","plot3D","lattice",
          "dplyr","knitr") 
for (pkg in pkgs) {
  if (! (pkg %in% rownames(installed.packages()))) { install.packages(pkg) }
  require(pkg, character.only = TRUE)
}
rm(pkgs, pkg)

# Remove previous data
rm(list=ls(all=TRUE))

# Loading packages
pkgs <- c("scales","car","RColorBrewer",
          "scatterplot3d","plot3D","lattice",
          "dplyr","knitr") 
for (pkg in pkgs) {
  if (! (pkg %in% rownames(installed.packages()))) { install.packages(pkg) }
  require(pkg, character.only = TRUE)
}

# Remove pkgs and pkg
rm(pkgs, pkg)

########## Function obtained from the internet https://github.com/ChrKoenig/R_marginal_plot/blob/master/marginal_plot.R
####
marginal_plot = function(x, y, group = NULL, data = NULL, lm_formula = y ~ x, bw = "nrd0", alpha = 1, plot_legend = T, ...){
  require(scales)
  ###############
  # Plots a scatterplot with marginal probability density functions for x and y. 
  # Data may be grouped or ungrouped. 
  # For each group, a linear fit is plotted. The model can be modified using the 'lm_formula' argument. Setting 'lm_formula' to NULL prevents plotting model fits.
  # The 'bw' argument specifies the bandwidth rule used for estimating probability density functions. See ?density for more information.
  # For large datasets, opacity may be decreased by setting alpha to a value between 0 and 1.
  # Additional graphical parameters are passed to the main plot, so you can customize axis labels, titles etc.
  ###############
  moreargs = eval(substitute(list(...)))
  
  # prepare consistent df
  if(missing(group)){
    if(missing(data)){
      if(length(x) != length(y)){stop("Length of arguments not equal")}
      data = data.frame(x = as.numeric(x), y = as.numeric(y))
    } else {
      data = data.frame(x = as.numeric(data[,deparse(substitute(x))]), 
                        y = as.numeric(data[,deparse(substitute(y))]))
    }
    if(sum(!complete.cases(data)) > 0){
      warning(sprintf("Removed %i rows with missing data", sum(!complete.cases(data))))
      data = data[complete.cases(data),]
    }
    group_colors = "black"
  } else {
    if(missing(data)){
      if(length(x) != length(y) | length(x) != length(group)){stop("Length of arguments not equal")}
      data = data.frame(x = as.numeric(x), y = as.numeric(y), group = as.factor(group))
    } else {
      data = data.frame(x = as.numeric(data[,deparse(substitute(x))]), 
                        y = as.numeric(data[,deparse(substitute(y))]),
                        group = as.factor(data[,deparse(substitute(group))]))
    }
    if(sum(!complete.cases(data)) > 0){
      warning(sprintf("Removed %i rows with missing data", sum(!complete.cases(data))))
      data = data[complete.cases(data),]
    }
    data = subset(data, group %in% names(which(table(data$group) > 5)))
    data$group = droplevels(data$group)
    group_colors = rainbow(length(unique(data$group)))
  } 
  
  # log-transform data (this is need for correct plotting of density functions)
  if(!is.null(moreargs$log)){
    if(!moreargs$log %in% c("y", "x", "yx", "xy")){
      warning("Ignoring invalid 'log' argument. Use 'y', 'x', 'yx' or 'xy.")
    } else {
      data = data[apply(data[unlist(strsplit(moreargs$log, ""))], 1, function(x) !any(x <= 0)), ]
      data[,unlist(strsplit(moreargs$log, ""))] = log10(data[,unlist(strsplit(moreargs$log, ""))])
    }
    moreargs$log = NULL # remove to prevent double logarithm when plotting
  }
  
  # Catch unwanted user inputs
  if(!is.null(moreargs$col)){moreargs$col = NULL}
  if(!is.null(moreargs$type)){moreargs$type = "p"}
  
  # get some default plotting arguments
  if(is.null(moreargs$xlim)){moreargs$xlim = range(data$x)} 
  if(is.null(moreargs$ylim)){moreargs$ylim = range(data$y)}
  if(is.null(moreargs$xlab)){moreargs$xlab = deparse(substitute(x))}
  if(is.null(moreargs$ylab)){moreargs$ylab = deparse(substitute(y))}
  if(is.null(moreargs$las)){moreargs$las = 1} 
  
  # plotting
  tryCatch(expr = {
    ifelse(!is.null(data$group), data_split <- split(data, data$group), data_split <- list(data))
    orig_par = par(no.readonly = T)
    par(mar = c(0.25,5,1,0))
    layout(matrix(1:4, nrow = 2, byrow = T), widths = c(10,3), heights = c(3,10))
    
    # upper density plot
    plot(NULL, type = "n", xlim = moreargs$xlim, ylab = "density",
         ylim = c(0, max(sapply(data_split, function(group_set) max(density(group_set$x, bw = bw)$y)))), main = NA, axes = F)
    axis(2, las = 1)
    mapply(function(group_set, group_color){lines(density(group_set$x, bw = bw), col = group_color, lwd = 2)}, data_split, group_colors)
    
    # legend
    par(mar = c(0.25,0.25,0,0))
    plot.new()
    if(!missing(group) & plot_legend){
      legend("center", levels(data$group), fill = group_colors, border = group_colors, bty = "n", title = deparse(substitute(group)), title.adj = 0.1)
    }
    
    # main plot
    par(mar = c(4,5,0,0))
    if(missing(group)){
      do.call(plot, c(list(x = quote(data$x), y = quote(data$y), col = quote(scales::alpha("black", alpha))), moreargs))
    } else {
      do.call(plot, c(list(x = quote(data$x), y = quote(data$y), col = quote(scales::alpha(group_colors[data$group], alpha))), moreargs))
    }
    axis(3, labels = F, tck = 0.01)
    axis(4, labels = F, tck = 0.01)
    box()
    
    if(!is.null(lm_formula)){
      mapply(function(group_set, group_color){
        lm_tmp = lm(lm_formula, data = group_set)
        x_coords = seq(min(group_set$x), max(group_set$x), length.out = 100)
        y_coords = predict(lm_tmp, newdata = data.frame(x = x_coords))
        lines(x = x_coords, y = y_coords, col = group_color, lwd = 2.5)
      }, data_split, rgb(t(ceiling(col2rgb(group_colors)*0.8)), maxColorValue = 255))
    }
    
    # right density plot
    par(mar = c(4,0.25,0,1))
    plot(NULL, type = "n", ylim = moreargs$ylim, xlim = c(0, max(sapply(data_split, function(group_set) max(density(group_set$y, bw = bw)$y)))), main = NA, axes = F, xlab = "density")
    mapply(function(group_set, group_color){lines(x = density(group_set$y, bw = bw)$y, y = density(group_set$y, bw = bw)$x, col = group_color, lwd = 2)}, data_split, group_colors)
    axis(1)
  }, finally = {
    par(orig_par)
  })
}

# Load Bank Dataset
df.1<-read.table("~/Documents/GitHub/RProjectsVL/Data/P1-4.DAT",
                 col.names = c("Sales","Profits","Assets"))
# First plot
marginal_plot(x=df.1$Sales,y=df.1$Profits,
              xlab="Sales",ylab="Profits")
# This plot shows that there is positive correlation between Sales and Profits with
# somewhat of a linear relationship, but it can also be said that due to the small sample size,
# this could be misleading.

# Second plot
marginal_plot(x=df.1$Profits,y=df.1$Assets,
              xlab="Profits",ylab="Assets")

# In the second plot, we actually see negative correlation between Profits and Assets.

# Third plot
marginal_plot(x=df.1$Sales,y=df.1$Assets,
              xlab="Sales",ylab="Assets")

# In the third plot, we can see negative correlation between Sales and Assets.

# Load the Radiotherapy Dataset
df.2<-read.table("~/Documents/GitHub/RProjectsVL/Data/T1-7.DAT",
                 col.names = c("Symptoms","Activity","Sleep","Food",
                               "Appetite","Skin"))

# Marginal Plot for Amount of Activity vs Amount of Sleep
marginal_plot(x=df.2$Activity,y=df.2$Sleep,xlab="Amount of Activity",ylab="Amount of Sleep")

# For this plot, we can see that there is positive correlation between the amount of activity and the 
# amount of sleep, but we can also see the presence of possible outliers that shown in the top left corner.

# Load the National Track Records for Women Dataset
df.3<-read.table("~/Documents/GitHub/RProjectsVL/Data/T1-9.dat",header = FALSE,
                 col.names = c("Country", "s100", "s200", "s400","m800","m1500","m3000","Marathon"))

# Convert country to character and use as row name
df.3$Country<-as.character(df.3$Country)
df.a= df.3[, -1]

# Mean
X<-apply(df.a,2,mean)
X

# Variance 
S<-var(df.a)
S

# Correlation
R<-cor(df.a)
R

# The results show that there is positive correlation between the groups with the largest
# coming from races that are similar.

# Convert to Meters Per Second
df.b<-df.a
df.b[,1]<-100/df.b[, 1]
df.b[,2]<-200/df.b[, 2]
df.b[,3]<-400/df.b[, 3]
df.b[,4:7]<-60*df.b[, 4:7]
df.b[,4]<-800/df.b[, 4]
df.b[,5]<-1500/df.b[, 5]
df.b[,6]<-3000/df.b[, 6]
df.b[,7]<-42195/df.b[, 7]

# Mean
X2<-apply(df.b,2,mean)
X2

# Variance
S2<-var(df.b)
S2

# Correlation
R2<-cor(df.b)
R2

# The results for this problem are similar to our previous question. We see positive
# correlation between groups with emphasis on the races with similar distances.

# Load the Bankruptcy Dataset
df.4<-read.table("~/Documents/GitHub/RProjectsVL/Data/T11-4.DAT",header = FALSE,
                 col.names = c("X1CashFlow/TotalDebt","X2NetIncome/TotalAssets",
                               "X3CurrentAssets/CurrentLiabilites","X4CurrentAssets/NetSales",
                               "Population"))

# Scatter 3D plot
scatterplot3d(x=df.4$X3CurrentAssets.CurrentLiabilites,y=df.4$X1CashFlow.TotalDebt,z=df.4$X2NetIncome.TotalAssets,xlab = "CurrentAssets/CurrentLiabilites",
              ylab="CashFlow/TotalDebt",zlab="NetIncome/TotalAssets",color=par("col"),main="3D Scatterplot X2 X3 X1")

# The plot suggests there could be some outliers towards the top right and the plot also
# looks like a cigar but bent towards the top.

# Rearrange Bankruptcy Dataset
df.5<-data.frame(a=df.4$X3CurrentAssets.CurrentLiabilites,b=df.4$X1CashFlow.TotalDebt,
                 c=df.4$X2NetIncome.TotalAssets,d=df.4$X4CurrentAssets.NetSales,
                 e=df.4$Population)

# Change d to numeric and e to a factor
df.5$d<-as.numeric(df.5$d)
df.5$e<-as.factor(df.5$e)

# Second Scatter 3D plot showing Bankruptcy and NonBankruptcy
df.plot<-scatterplot3d(df.5[df.5$e=="1",],box=FALSE, pch=16,xlab="NetIncome/TotalAssets", ylab="CurrentAssets/CurrentLiabilites",zlab="CashFlow/TotalDebt",zlim=c(-0.5,1),
                       type="h", main="3D Scatterplot X2 X3 X1",
                       xlim = c(0,4),ylim = c(-0.5,1),highlight.3d=TRUE)
df.plot$points3d(df.5[df.5$e=="0",],col="red",type="h",pch=16)
legend("topright",legend=c("Non Bankruptcy","Bankruptcy"),col = c("black","red"),lty = 1,box.lty=0,pch=19)

# This plot shows that there is an outlier for the bankruptcy firms, which shows up in the
# non-bankruptcy firms.

# Load the Public Utility Company Dataset
df.6<-read.table("~/Documents/GitHub/RProjectsVL/Data/T12-4.DAT",header = FALSE,
                 col.names = c("X1FixedChargeRatio","X2RateofReturnonCapital","X3CostPerKWcp",
                               "X4AnnualLoadFactor","X5PeakDemandGrowth","X6Sales",
                               "X7PercentNuclear","X8FuelCost","Company"))
# Create a Star Chart
par(mfrow=c(2,2))
stars(df.6[,1:3],locations=c(0,0),key.loc=c(0,0),main="Group 1")
stars(df.6[,4:6],locations=c(0,0),key.loc=c(0,0),main="Group 2")
stars(df.6[,5:8],locations=c(0,0),key.loc=c(0,0),main="Group 3")
stars(df.6[,2:5],locations=c(0,0),key.loc=c(0,0),main="Group 4")

# Reset plot parameters
dev.off()

# Load the National Park Dataset Dataset
df.7<-read.table("~/Documents/GitHub/RProjectsVL/Data/T1-11.dat",header = FALSE,
                 col.names = c("Size","Visitors"))

# Add a new variable for the parks
df.7$Park<-factor(rep(1:length(df.7$Size)))

# plot data
plot(x=df.7$Visitors,y=df.7$Size, main="Scatter Plot of X and Y",xlab="Number of visitors(in millions)",ylab="Size (in Acres)")
abline(lm(Size~Visitors,data=df.7),col="blue",lwd=3, lty=3)

# If we take a look at the plot, we can clearly see that there is an outlier that is effecting model. 
# To figure our which park is the outlier, lets take a look at the data.
head(df.7,n=15)

# Comparing the dataset to the plot, we figure out that Park 7 or 
# The Great Smokey National Park is the outlier.

# Before we do anything, lets check the correlation between Visitors and Size.
cor(x=df.7$Visitors,y=df.7$Size)

# It comes out at 0.1725274. So now lets remove The Great Smokey National Park and plot the data and 
# rerun the cor() to see if it improves.

# Remove The Great Smokey National Park.
df.7<-df.7[-7,]

# Update scatter plot
plot(x=df.7$Visitors,y=df.7$Size, main="Updated Scatter Plot of X and Y",xlab="Number of visitors(in millions)",ylab="Size (in Acres)")
abline(lm(Size~Visitors,data=df.7),col="blue",lwd=3, lty=3)

# It definitly looks better so now lets also rerun the cor().
cor(x=df.7$Visitors,y=df.7$Size)

# The correlation coefficient improves to 0.3907829.

knit()
