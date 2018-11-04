var express = require('express'),
    path = require('path'),
    home = require('./routes/home.js'),
    fastQC = require('./routes/fastQC.js'),
    customer = require('./routes/customer.js'),
    trim = require('./routes/trim.js');
var app = express();


app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
//app.use(express.bodyParser({ keepExtensions: true, uploadDir: path.join(__dirname, '/pictures')}));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', home.index);
//app.post('/customer/create', customer.createCustomer);

app.get('/contact', home.contact);
app.get('/fastQC', fastQC.index);
app.post('/fastQC/upload', fastQC.uploadFastQC);
app.post('/fastQC/trim', ()=>{});

app.get('/customer/create', customer.create);
app.get('/customer/details/:id', customer.details);
app.get('/customer/picture/:id', customer.picture);
app.post('/customer/create', customer.createCustomer);
app.get('/customer/edit/:id', customer.edit);
app.post('/customer/edit/:id', customer.editCustomer);
app.delete('/customer/edit/:id', customer.delete);

app.locals.clock = { datetime: new Date().toUTCString()};

app.listen(3000);

module.exports = app;
