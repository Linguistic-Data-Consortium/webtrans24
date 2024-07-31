# Establishing roles and policies for WebTrans

## Roles

IAM roles are a bit like users in that they can be granted access to AWS resources through policies. Unlike users, though, they don't have the ability to log in/generate permanent access keys; roles are "assumed" by users and services, allowing them to perform actions using the role's permissions.

### Cognito role

This role is used by front end code, primarily to permit access to data stored in S3. This role and its associated permissions were configured during [Cognito](congito.md) setup.

### ECS task execution role

This role is used by ECS to launch containers on our behalf. As such, it needs permissions to do things like pull images from your private repositories, create log groups in CloudWatch, and access values we've stored in Secrets Manager so it can set them in the container environment.  

To create the `ecsTaskExecutionRole`, follow [these directions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html#create-task-execution-role). When that's complete, go to the **Roles** section of the [IAM web console](https://console.aws.amazon.com/iam/home#/roles) and find the role, then click it's name to view the detail page.  

In the **Permisions** tab, select `Create inline policy` from the **Add permissions** drop down list, then create the policy:

* Choose `Secrets manager` from the **Service** drop down list, then select `GetSecretValue` the **Read** section.
  * In the **Resources** section , click **Add ARNs** to set the secrets the role can access
    * Enter the ARN of the secret into the **Resource ARN** textbox
    * NOTE: if you followed the naming advice while [setting up secrets](secrets.md), your secrets should have a common prefix, e.g. `webttrans/` in `webtrans/smtp_password` or `webtrans/postgres_password`. This lets you set a policy that covers all secrets with that prefix without having to specify them individually.  
      To take advantage of this, just edit the string in **Resource secret** to just the prefix plus asterisk, e.g., `webtrans/*`.
    * When done, click **Add ARNs**
* Click **Add more permissions**, then select `CloudWatch Logs` from the **Service** drop down list
  * Add permissions
    * From the **List** section, select `DescribeLogGroups`
    * From the **Write** section, select `CreateLogGroup`
  * Make sure `All` is selected in the **Resources** subsection
* Click **Add more permissions**, then select `EventBridge` from the **Service** drop down list
  * Add permissions
    * From the **List** section, select `ListTargetsByRule`
    * From the **Read** section, select `DescribeRule`
    * From the **Write** section, select `PutRule` and `PutTargets`
  * Make sure `All` is selected in the **Resources** subsection
* Click **Next**, give the policy a name, then click **Create policy**

### ECS task role

This the role is used by WebTrans to use AWS services as part of the application.

* Click **Create role**
* Select `Custom trust policy` in the **Trusted entity type** section
* Edit the policy in the **Custom trust policy** subsection
  * click **Add** button in the **Add a principal** box on the right hand side of the editor
    * select `AWS Services` from the principal type drop down list
    * enter `ecs-tasks.amazonaws.com` in the **ARN** text box
    * click **Add principal**
  * click **Add** button in the **Add a condition** box on the right hand side of the editor
    * From the **Condition  key**  combo box, select `aws:SourceArn`
    * From the **Operator** drop down list, select `ArnLike`
    * Enter a (partial) arn in the **Value** box  
      this has the format  `arn:aws:ecs:${region}:${account_id}:*`  where `${region}` is the AWS region where the role is defined and `${account_id}` is your account ID[^account_id]. Note the final colon and asterisk (`:*`) _**must**_ be included in the string.
    * Click **Add condition**
* Click **Next**, then click **Next** again to skip the **Add permissions** step.
* Give the policy a name and description, then click **Create role**.
* Find the role you just added in the **Roles** section of the [IAM web console](https://console.aws.amazon.com/iam/home#/roles), then click it's name to view the detail page.
* In the **Permissions** tab, select `Create inline policy` from the **Add permissions** drop down list, then edit the policy:
  * Choose `Cognito Identiy` from the **Service** drop down list, select the `GetOpenIdTokenForDeveloperIdentity` from the **Read** section
  * In the **Resource** section, click `Add ARNs`
    * Ensure `This account` is selected
    * Enter your AWS region in **Resource region**
    * Enter the `Identity pool ID` for the identity pool you created when [setting up Cognito](cognito.md)
    * When done, click **Add ARNs**
  * Click **Add more permissions**, then select `S3` from the **Service** drop down list
    * Add permissions
      * From the  **List** section, select `ListBucket` and `ListAllMyBuckets`
      * From the **Read** section, select `GetObject`
    * Click **Add ARNs** in the **bucket** portion of in the **Resources** section.
      * Enter the WebTrans S3 bucket name
      * Click **Add ARNs**
    * Click **Add ARNs** in the **object** portion of in the **Resources** section.
      * Enter the WebTrans S3 bucket name
      * Select the **Any object name** checkbox
      * Click **Add ARNs**
  * Click **Next**, give the policy a name and then click **Create policy**.

## Notes

