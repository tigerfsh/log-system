import boto3

BUCKET_NAME = "loki-test"
aws_access_key_id = "WIEoUuuwlonePz5J"
aws_secret_access_key = "F17KaByzofy49PJ5tZ9NvIDwIjdVUI1R"

s3 = boto3.client("s3", endpoint_url="http://127.0.0.1:9000",
                  aws_access_key_id=aws_access_key_id,
                  aws_secret_access_key=aws_secret_access_key)

upload_file = "a.txt"
# with open(upload_file, "rb") as f:
#     s3.upload_fileobj(f, BUCKET_NAME, upload_file)


# object_list = s3.list_objects(Bucket=BUCKET_NAME)
# print(object_list)

download_file = "b.txt"
with open(download_file, 'wb') as f:
    s3.download_fileobj(BUCKET_NAME, upload_file, f)
