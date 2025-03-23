import swaggerAutogen from 'swagger-autogen';

const doc = {
  info: {
    title: 'API Testing',
    description: 'Dokumentasi API dengan Swagger Autogen',
  },
  host: '13.212.48.92:5000',
  schemes: ['http'],
};

const outputFile = './src/swagger-output.json';
const endpointsFiles = ['./src/server.js'];

swaggerAutogen()(outputFile, endpointsFiles).then(() => {
  // Jalankan server setelah dokumentasi tergenerate
  import('./server');
});
