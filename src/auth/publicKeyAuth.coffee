bunyan   = require 'bunyan'
log      = bunyan.createLogger name: 'publicKeyAuth'
env      = require '../env'
fs       = require 'fs'
crypto   = require 'crypto'
ssh2     = require 'ssh2'
ssh2_streams = require 'ssh2-streams';
buffersEqual = require 'buffer-equal-constant-time'

authorizedKeysFile = env.assert 'AUTHORIZED_KEYS'

module.exports = (ctx) ->
  if ctx.method is 'publickey'
    # try to find a match in the authorized keys
    log.info {user: ctx.username}, 'Checking public key against authorized keys'
    authorizedKey = null
    authorizedKeyIndex = 0 ;
    fs.readFileSync(authorizedKeysFile).toString().split('\n').forEach (line) ->
      authorizedKeyIndex++
      if line.length > 0
        pubKey = ssh2_streams.utils.genPublicKey(ssh2_streams.utils.parseKey(line))
        if ctx.key.algo is pubKey.fulltype and buffersEqual(ctx.key.data, pubKey.public)
          log.info 'Found authorized key matching client key at ' + authorizedKeysFile + ':' + authorizedKeyIndex
          authorizedKey = pubKey

    # no match: reject
    if authorizedKey == null
      log.info 'No authorized key matching the client key'
      return ctx.reject();

    if ctx.signature
      verifier = crypto.createVerify(ctx.sigAlgo);
      verifier.update(ctx.blob);
      if verifier.verify(authorizedKey.publicOrig, ctx.signature)
        log.info {user: ctx.username}, 'Public key auth succeeded'
        return ctx.accept()
      else
        log.warn {user: ctx.username}, 'Authentication failed'
        ctx.reject()
    else
      # if no signature present, that means the client is just checking
      # the validity of the given public key
      log.info {user: ctx.username}, 'No signature, the client is just checking validity of given public key'
      return ctx.accept();

  ctx.reject(['publickey']);