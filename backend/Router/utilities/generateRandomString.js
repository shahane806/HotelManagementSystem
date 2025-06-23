var createRandomString = (length)=>{
    const alphaNumeric =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()";
    let randomString = "";
    for (let i = 0; i < length; i++) {
      randomString += alphaNumeric.charAt(
        Math.floor(Math.random() * alphaNumeric.length)
      );
    }
    return randomString
}

module.exports = {createRandomString}