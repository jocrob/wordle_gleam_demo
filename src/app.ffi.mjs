export async function delay(amount, cb) {
    await timeout(amount);
    cb()
}

function timeout(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}