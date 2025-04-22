import swaggerAutogen from 'swagger-autogen';

const doc = {
  info: {
    title: 'API Testing',
    description: 'Dokumentasi API dengan Swagger Autogen',
  },
  host: '34.134.193.94:5000',
  schemes: ['http'],
};

const outputFile = './swagger-output.json';
const endpointsFiles = ['./server.js'];

swaggerAutogen()(outputFile, endpointsFiles).then(() => {
  // Jalankan server setelah dokumentasi tergenerate
  import('./server.js');
});
