
data.frame2csv <- function(d, obname, fname, fieldsep, how)
{
    d.names <- names(d)

    if(how == "R"){
        sink(paste0(fname, ".R"))
        cat(obname, ' <- read.table("', fname, '.csv", sep = "', fieldsep,
            '", header = TRUE, as.is = TRUE)\n\n', sep = "")
        for(column in d.names){
            xx <- d[[column]]
            if(is.factor(xx)){
                xx.levels <- gsub('"', '\\\\"', levels(xx))
                n.levels <- length(xx.levels)
                cat(obname, "$", column, " <- factor(", obname, "$", column,
                    ", levels = 1:", n.levels, ',\n  labels = c("', sep = "")
                cat(xx.levels[1], '"', sep = "")
                if(n.levels > 1) cat(", ")
                i <- 2
                len <- 2
                n.levels1 <- n.levels - 1
                while(i < n.levels){
                    len <- len + nchar(xx.levels[i]) + 4
                    if(len > 80){
                        cat("\n    ")
                        len <- nchar(xx.levels[i]) + 6
                    }
                    cat('"', xx.levels[i], '", ', sep = "")
                    i <- i + 1
                }
                if(len > 80) cat("\n  ")
                if(n.levels > 1) cat('"', xx.levels[n.levels], '"', sep = "")
                cat("))\n")
            }
        }
        if(!is.null(attr(d, "variable.labels"))){
            cat('\nattr(', obname, ', "variable.labels") <- ', sep = "")
            dput(attr(d, "variable.labels"))
            cat("\n")
        }
        for(column in d.names){
            xx <- d[[column]]
            xx.label <- attr(xx, "label")
            if(!is.null(xx.label)){
                cat("attr(", obname, "$", column, ', "label") <- "', xx.label,
                    '"\n', sep = "")
            }
        }
        cat("save(", obname, ", file = \"", fname, ".RData\")\n", sep = "")
        sink()
    } else if(how == "SPSS"){
        sink(paste0(fname, ".sps"))
        cat("GET DATA\n")
        cat("  /TYPE=TXT\n")
        cat("  /FILE='", fname, ".csv", "'\n", sep = "")
        cat("  /DELCASE=LINE\n")
        cat("  /DELIMITERS=\"", fieldsep, "\"\n", sep = "")
        cat("  /ARRANGEMENT=DELIMITED\n")
        cat("  /FIRSTCASE=2\n")
        cat("  /VARIABLES=\n")
        for(column in d.names){
            cat("  ", column, " ", sep = "")
            xx <- d[[column]]
            if(is.character(xx)){
                mnc <- max(nchar(xx), na.rm = TRUE)
                if(mnc == 0)
                    mnc <- 1
                cat("A", mnc, "\n", sep = "")
            } else if(is.factor(xx)){
                nlevs <- length(levels(xx))
                if(nlevs < 10) cat("F1.0\n")
                else if(nlevs > 9 && nlevs < 100) cat("F2.0\n")
                else if(nlevs > 99) cat("F3.0\n")
            } else if(is.numeric(xx)){
                if(sum(grepl("(chron|dates|times)", class(xx))) > 0){
                    cat("A", max(nchar(as.character(xx)), na.rm = TRUE), "\n", sep = "")
                } else {
                    cat("F", max(nchar(as.character(xx)), na.rm = TRUE), ".0\n", sep = "")
                }
            } else cat("error: undefined type\n")
        }
        cat("  .\n")
        cat("EXECUTE.\n\n")

        for(column in d.names){
            xx <- d[[column]]
            xx.label <- attr(xx, "label")
            if(!is.null(xx.label))
                cat("VARIABLE LABELS ", column, ' "', xx.label, '" .\n', sep = "")
        }
        cat("\n")

        for(column in d.names){
            xx <- d[[column]]
            if(is.factor(xx)){
                cat("VALUE LABELS ", column, "\n", sep = "")
                xx.levels <- levels(xx)
                len <- length(xx.levels)
                for(i in 1:len){
                    if(i < len){
                        cat("  ", i, ' "', xx.levels[i], '"\n', sep = "")
                    } else {
                        cat("  ", i, ' "', xx.levels[i], '" .\n', sep = "")
                    }
                }
                cat("\n")
            }
        }
        cat("SAVE OUTFILE='", fname, ".sav'\n  /COMPRESSED.\n", sep = "")
        sink()
    }

    if(how != "char"){
        for(column in d.names)
            if(is.factor(d[[column]])) d[[column]] <- as.numeric(d[[column]])
    }

    if(fieldsep == "\\t")
        fieldsep <- "\t"
    write.table(d, file = paste0(fname, ".csv"), sep = fieldsep,
                col.names = TRUE, row.names = FALSE, na = "")
}
