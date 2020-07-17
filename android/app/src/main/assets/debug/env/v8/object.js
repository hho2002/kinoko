let cache = [];

class Object {
    static class_name = 'gc::Object';

    static reg() {
        _registerClass(this, this.class_name);   
    }

    static new() {

        let argv = [];
        for (let i = 0, t = arguments.length; i < t; ++i) {
            argv.push(arguments[i]);
        }

        let obj = new (Function.prototype.bind.apply(this, argv));
        _newObject(obj, this.class_name, argv);

        return obj;
    }

    destory() {
        _destroyObject(this);
    }

    _call(name) {
        let argv = [];
        for (let i = 1, t = arguments.length; i < t; ++i) {
            argv.push(arguments[i]);
        }
        return _call.apply(this, [name, argv]);
    }

    static _call(name) {
        let argv = [];
        for (let i = 1, t = arguments.length; i < t; ++i) {
            argv.push(arguments[i]);
        }
        return _callStatic.apply(this, [name, argv]);
    }

    _keep() {
        let idx = cache.indexOf(this);
        if (idx < 0) {
            cache.push(this);
        }
    }

    _release() {
        let idx = cache.indexOf(this);
        if (idx >= 0) {
            cache.splice(idx, 1);
        }
    }
}

Object.reg();

module.exports = Object;