import boto3, json, logging

s3_resource = boto3.resource('s3')
s3_client = boto3.client('s3')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info(event)
    record_count = 0

    for record in event['Records']:

        bucket = record['s3']['bucket']['name']
        object_key = record['s3']['object']['key']
        partition = '/'.join(object_key.split('/')[2:-2])
        object_name = object_key.split('/')[-1]
    
        response = s3_client.get_object(Bucket=bucket, Key=object_key)
        findings = '['+ response['Body'].read().decode('utf-8').replace('}{','},\n{') +']'
    
        findings_list = json.loads(findings)
        record_count += len(findings_list)
        output = {}

        for item in findings_list:
            # For native AWS Services.  GuardDuty,Security Hub, Access Analyzer
            # have been tested.
            product_type = item['resources'][0].split('/')[3]
            if product_type.startswith('arn:aws'):
                product_node = item['resources'][0].split('/')[3]
                logger.info(f'product node is {product_node}')
                product = product_node.split(':')
                product_name = product[2]
                region = product[3]
                account_id = product[4]
            # Handle default and 3rd party product. Cloud Custodian falls into this category
            # Other integrated product may have format that can cause problem
            else:
                product_name = item['resources'][0].split('/')[2]
                region = item['resources'][0].split('/')[3]
                account_id = item['resources'][0].split('/')[4]
            
            key = account_id + '/' + product_name + '/'+region
            logger.info( f'key is {key}')

            # Ensure Athena compatibility, remove '-' from 'detail-type'
            item['detailType'] = item['detail-type']
            item.pop('detail-type', None)

            if key not in output:
                output[key] = [item]
            else:
                output[key].append(item)
                  
        for key in output:
            s3_path = 'AWSLogs/'+ key +'/'+partition  + '/'  + object_name + '.json'
            body = ''
            for version in output[key]:
                body += json.dumps(version) + '\n'
            s3_resource.Bucket(bucket).put_object(Key=s3_path, Body=body)
    return 'Processed: ' + str(record_count) + ' logs'