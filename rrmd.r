# First, let's check what's happening with kableExtra
print("Checking kableExtra installation...")

# Check if it's installed but not loading
if ("kableExtra" %in% installed.packages()) {
  print("kableExtra is installed, testing load...")
  library(kableExtra)
} else {
  print("kableExtra is NOT installed, installing now...")
  
  # Try different installation methods
  tryCatch({
    install.packages("kableExtra", dependencies = TRUE)
    print("Installation attempt 1 completed")
  }, error = function(e) {
    print(paste("Method 1 failed:", e$message))
  })
}

# Check installation again
if ("kableExtra" %in% installed.packages()) {
  print("✓ kableExtra is now installed!")
} else {
  print("✗ kableExtra installation failed")
}