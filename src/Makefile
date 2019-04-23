BASE_URL := "https://murray.systems/"

HUGO_FLAGS := --minify

PUBLIC_PATH := public
RESOURCES_PATH = resources

BUCKET_URL := "s3://murray-systems"


build:
	hugo             \
	  ${HUGO_FLAGS}  \
	  --baseURL=${BASE_URL};


deploy: build
	aws s3 sync --delete ${PUBLIC_PATH} ${BUCKET_URL};


clean:
	$(RM) -rf ${RESOURCES_PATH}


fclean: clean
	$(RM) -rf ${PUBLIC_PATH}
