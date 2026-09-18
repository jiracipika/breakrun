const { cpSync, mkdirSync, readdirSync } = require("fs");
mkdirSync("dist", { recursive: true });
cpSync("web", "dist", { recursive: true });
console.log("dist:", readdirSync("dist").join(", "));
