### Store a secure tfstate in s3 use_lockfile true

terraform {
   backend "s3"	{
     bucket         = "teng-aws-tf-three-tier-project-tfstate"
     key            = "environments/dev/terraform.tfstate"
     region         = "ap-southeast-2"
     use_lockfile   = true #  Native S3 locking
     encrypt        = true
   }	
}
