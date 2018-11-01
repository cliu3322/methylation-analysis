var formidable = require('formidable');
var path = require('path');
exports.index = function (req, res) {
    res.render('fastQC/index');
};

exports.uploadFastQC = function (req, res) {

  let form = new formidable.IncomingForm()

  /**
   * Options
   */
  form = Object.assign(form, {
    multiples: true,
    keepExtensions: true,
    uploadDir: path.join(__dirname, '../uploads/'), // Set standard upload dir
    encoding: 'utf-8',
    type: 'multipart', // or urlencoded
    maxFieldsSize: 20 * 1024 * 1024, // default = 20 * 1024 * 1024 = 20mb
    maxFields: 1000, // Max files & fields - default = 1000
    hash: false, // sha1, md5 or false
    // @note - Disable field & file event listeners and let you handle upload yourself
    onPart (part) {
      part.addListener('data', packet => {
        // console.log('Packet received', packet.toString()) // Raw packet data
        // packet_a + packet_b + packet_c + ... = file data
      })
      // Handle part / file only if .mov is not included in filename
      if (part.filename && part.filename.indexOf('.mov') === -1) {
        form.handlePart(part)
      // Or if filename is not set
      } else if (!part.filename) {
        form.handlePart(part)
      }
    }
  })

  /**
   * Events
   */
  form.on('fileBegin', (name, file) => {
    // file.name - basename with extension
    // file.size - currently uploaded bytes
    // file.path - beeing written to
    // file.type - mime
    // file.lastModifiedDate - date object or null
    // file.hash - hex digest if set
    // Changing file upload path can also be done here:
    file.path = path.join(__dirname, '../uploads/' + file.name)
  })
  form.on('progress', (bytesReceived, bytesExpected) => {
    console.log('Progress', bytesReceived, bytesExpected)
  })
  form.on('error', (err) => {
    console.error(err)
  })
  form.on('aborted', () => {
    console.error(new Error('Aborted'))
  })
  form.on('end', () => {
    console.log('End')
  })
  form.on('field', (name, value) => {
    console.log('Field', name, value)
  })
  form.on('file', (name, file) => {
    console.log('File', name, file.type)
  })

  /**
   * Function
   *
   * Passes request from express to formidable for handling.
   * Second arg is a callback executed on complete & returns all data
   *
   */
  form.parse(req, (err, fields, files) => {
    if (err) {
      return res.status(500).json({ error: err })
    } else {
      return res.status(200).json({ uploaded: true })
    }
  })

}
