import swaggerJSDoc from "swagger-jsdoc";
import swaggerUi from "swagger-ui-express";

const options = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "My App API Docs",
      version: "1.0.0",
      description: "API documentation for my Express app",
    },
    servers: [
      {
        url: "http://localhost:3300/v1", 
      },
    ],
  },
  apis: ["./src/routes/**/*.js", "./src/controllers/**/*.js"],
};

const swaggerSpec = swaggerJSDoc(options);

export { swaggerUi, swaggerSpec };
