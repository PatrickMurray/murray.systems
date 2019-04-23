BASE_URL := "https://murray.systems/"

HUGO_FLAGS := --minify

PUBLIC_PATH := public
RESOURCES_PATH = resources

BUCKET_URL := "s3://murray-systems.s3-us-east-1.amazonaws.com"

build:
	hugo             \
	  ${HUGO_FLAGS}  \
	  --baseURL=${BASE_URL};
	fclean	


deploy: all
	aws s3 sync --delete ${PUBLIC_PATH} ${BUCKET_URL};

clean:
	$(RM) -rf ${PUBLIC_PATH}


fclean: clean
	$(RM) -rf ${PUBLIC_PATH}
