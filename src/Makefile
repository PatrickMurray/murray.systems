BASE_URL := "https://murray.systems/"

HUGO_FLAGS := --minify

PUBLIC_PATH := public
RESOURCES_PATH = resources

AWS_BUCKET_URL := "s3://murray-systems"
AWS_CLOUDFRONT_DISTRIBUTION := "E2ZR0FND2MJZ63"


build:
	hugo             \
	  ${HUGO_FLAGS}  \
	  --baseURL=${BASE_URL};


deploy: build
	aws s3 sync  \
	  --delete   \
	  ${PUBLIC_PATH} ${AWS_BUCKET_URL};
	
	aws cloudfront create-invalidation                  \
	  --distribution-id ${AWS_CLOUDFRONT_DISTRIBUTION}  \
	  --paths "/*";


clean:
	$(RM) -rf ${RESOURCES_PATH}


fclean: clean
	$(RM) -rf ${PUBLIC_PATH}
