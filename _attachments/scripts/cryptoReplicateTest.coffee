cloudDB = new PouchDB('http://admin:password@localhost:5984/test')
pouchNotEncrypted = new PouchDB('pouchNotEncrypted')
pouchEncrypted = new PouchDB('pouchEncrypted')
pouchEncrypted.crypto("password")

cloudDB.replicate.to(pouchNotEncrypted)
.then (replicationResult) ->
  console.log replicationResult
  pouchNotEncrypted.get("doc")
.then (doc) ->
  console.log "pouchNotEncrypted before update:"
  console.log doc
  doc.a = "b"
  pouchNotEncrypted.put(doc)
.then  ->
  console.log "pouchNotEncrypted after update:"
  console.log doc
  pouchNotEncrypted.replicate.to(cloudDB)
.then (replicationResult) ->
  console.log replicationResult
  cloudDB.get("doc")
.then (doc) ->
  console.log "Cloud doc after replication:"
  console.log doc
  cloudDB.replicate.to(pouchEncrypted)
.then (replicationResult) ->
  console.log replicationResult
  pouchEncrypted.get("doc")
.then (doc) ->
  console.log "pouchEncrypted before update:"
  console.log doc
  doc.c = "d"
  pouchEncrypted.put(doc)
.then (doc) ->
  console.log "pouchEncrypted after update:"
  console.log doc
  pouchEncrypted.replicate.to(cloudDB)
.then (replicationResult) ->
  console.log replicationResult
  cloudDB.get("doc")
.then (doc) ->
  console.log "Cloud doc after replication:"
  console.log doc
