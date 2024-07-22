# Setting CORS Headers for S3 buckets

In order to load audio from S3, we need to configure the [Cross-Origin Resource Sharing (CORS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) headers for the bucket we're loading data from.

## Howto

Go to the [Buckets](https://console.aws.amazon.com/s3/buckets) section of the S3 web console, find the bucket you use for your WebTrans data, and click the name to bring up the detail page. Click on the _Permissions_ tab and go to the _Cross-origin resource sharing_ section at the very bottom of the page. Click the _Edit_ button, and paste the following into the dialog that appears:

```json
[
    {
        "AllowedHeaders": [
            "*"
        ],
        "AllowedMethods": [
            "GET",
            "PUT",
            "POST",
            "HEAD",
            "OPTIONS"
        ],
        "AllowedOrigins": [
            "*",
        ],
        "ExposeHeaders": [
            "x-amz-meta-uid"
        ],
        "MaxAgeSeconds": 3000
    }
]
```

Click `Save changes`.

## Notes

The origins should probably be locked down a bit. For example, if the public facing instance were running at `https://webtrans.example.edu` changing `AllowedOrigins` to:

```json
        "AllowedOrigins": [
            "http://localhost:3000",
            "https://webtrans.example.edu",
        ]
```

would permit requests from a local development instance, as well as the production site. It might be good to specify a list of `AllowedHeaders`, too.
