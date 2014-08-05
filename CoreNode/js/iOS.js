var iOS = process.binding('ios');

exports.binding = function binding(name) {
    return iOS.binding(name);
};
