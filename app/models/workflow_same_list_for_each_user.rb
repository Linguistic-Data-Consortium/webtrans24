class WorkflowSameListForEachUser < WorkflowBucketUser

  def create_kits_from_bucket(excluding:, limit:)
    exclude = {}
    excluding.each do |k|
      exclude[k] = true
    end
    task.meta['docid'] =~ /s3:\/\/(.+?)\/(.+)/
    bucket, key = $1, $2
    x = s3.get_object( bucket: bucket, key: key).body.read.split
    count = 0
    x.each do |uid|
      next if exclude[uid]
      kit = create_default_kit
      kit.source = { uid: uid, id: uid, filename: uid }
      kit.source_uid = uid
      kit.save!
      count += 1
      break if count == limit
    end
  end

end
