// A lambda function that return Hello World

exports.handler = function () {
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: "Hello World!",
    }),
  };
};
