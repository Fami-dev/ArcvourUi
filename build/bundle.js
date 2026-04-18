const fs = require('fs');
const path = require('path');

const entryFile = process.argv[2];
const outputFile = process.argv[3];

if (!entryFile || !outputFile) {
    console.error("Usage: node bundle.js <entry> <output>");
    process.exit(1);
}

const modules = new Map();
let moduleIdCounter = 0;
const fileToId = new Map();

function resolvePath(currentFile, importPath) {
    let target = path.join(path.dirname(currentFile), importPath);
    if (!target.endsWith('.lua')) {
        if (fs.existsSync(target + '.lua')) {
            target += '.lua';
        } else if (fs.existsSync(path.join(target, 'Init.lua'))) {
            target = path.join(target, 'Init.lua');
        } else if (fs.existsSync(path.join(target, 'init.lua'))) {
            target = path.join(target, 'init.lua');
        }
    }
    return target;
}

function processFile(filePath) {
    filePath = path.resolve(filePath);
    if (fileToId.has(filePath)) {
        return fileToId.get(filePath);
    }

    console.log(`Processing: ${filePath}`);

    if (!fs.existsSync(filePath)) {
        console.error(`File not found: ${filePath}`);
        return null; // Or throw
    }

    const id = moduleIdCounter++;
    fileToId.set(filePath, id);

    let content = fs.readFileSync(filePath, 'utf8');

    // Simple regex to find requires.
    // Handles: require("path") and require('path')
    // Does NOT handle complex expressions.
    
    const requireRegex = /require\s*\(\s*["']([^"']+)["']\s*\)/g;
    
    let dependencies = [];
    
    content = content.replace(requireRegex, (match, importPath) => {
        const absoluteImportPath = resolvePath(filePath, importPath);
        const depId = processFile(absoluteImportPath);
        return `__bundle_require(${depId})`;
    });

    modules.set(id, content);
    return id;
}

const entryId = processFile(entryFile);

let outputContent = `
-- Bundled with custom JS bundler
local __modules = {}
local __cache = {}

local function __bundle_require(id)
    if __cache[id] then return __cache[id] end
    local loader = __modules[id]
    if not loader then error("Module " .. id .. " not found") end
    local result = loader()
    __cache[id] = result
    return result
end

`;

modules.forEach((content, id) => {
    outputContent += `__modules[${id}] = function()
${content}
end
`;
});

outputContent += `return __bundle_require(${entryId})`;

fs.writeFileSync(outputFile, outputContent);
console.log(`Bundled ${modules.size} files to ${outputFile}`);
