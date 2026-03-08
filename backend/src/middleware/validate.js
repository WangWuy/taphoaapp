const AppError = require('../utils/AppError');

const validate = (schema, source = 'body') => (req, _res, next) => {
    const { error, value } = schema.validate(req[source], {
        abortEarly: false,
        stripUnknown: true,
    });

    if (error) {
        const message = error.details.map(d => d.message).join(', ');
        return next(new AppError(message, 400));
    }

    req[source] = value;
    next();
};

module.exports = validate;
