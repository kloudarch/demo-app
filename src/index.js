// A lambda function that return Hello World

const handler = async (event) => {
  console.log(event);
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: "Hello World!",
    }),
  };
};

exports.handler = handler;
