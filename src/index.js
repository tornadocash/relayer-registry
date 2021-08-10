require('dotenv').config()

// eslint-disable-next-line require-await
async function main() {
  console.log('Hello, world!')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
