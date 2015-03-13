library(pscl)   # for generating IG variables
library(statmod)

xtrain <- read.csv("Assignment1XTraining.csv", header=TRUE)      # 150 x 90
ytrain <- read.csv("Assignment1YTraining.csv", header=FALSE)
xtest <- read.csv("Assignment1XTest.csv", header=TRUE)
ytest <- read.csv("Assignment1YTest.csv", header=FALSE)
set.seed(1234)

# initiating variables
n <- 10**4
betatraj <- matrix(rep(0, 90*(n+1)), c(90, n+1))  
alpha <- 10
nu <- 1
tauinv <- rep(0,90)
v <- 1  
# using results from lm to initiate betas
betatraj[,1] <- lm(ytrain[,1] ~ as.matrix(xtrain) - 1)$coefficient[1:90]


for (i in 2:(n+1)){
    # generating lambda
    lambda <- rgamma(90,10,1)
    
    # generating 1/tau
    for (j in 1:90){
        tauinv[j] <- rinvgauss(1, mean = lambda[j]*sqrt(v)/abs(betatraj[j,i-1]), dispersion = 1/lambda[j]^2)
    } 
    
    # generating v
    yxp <- t(ytrain[,1]-as.matrix(xtrain)%*%betatraj[,i-1])%*%(ytrain[,1]-as.matrix(xtrain)%*%betatraj[,i-1])
    v <- rigamma(1, (150+90)/2, (yxp/2) + t(betatraj[,i-1])%*%diag(tauinv)%*%betatraj[,i-1]/2)
    
    # generating beta
    betatraj[,i] <- mvrnorm(1, solve(t((as.matrix(xtrain))) %*% as.matrix(xtrain) + diag(tauinv))%*%t(as.matrix(xtrain))%*%ytrain[,1] , 
                            v*solve(t((as.matrix(xtrain))) %*% as.matrix(xtrain) + diag(tauinv)))
}

# autocorrelation
acf(betatraj[1,], main="autocorrelation")

# MSE 
betatest <- apply(betatraj[,1000:10001], 1, mean) # Burn in 1000
mean((betatest %*% t(xtest) - ytest)**2)  
# mse = 0.2265391