from iii import register_worker, InitOptions, Logger

worker = register_worker(
    "ws://10.0.1.252:49134",
    InitOptions(worker_name="math-worker"),
)

logger = Logger()


def add_handler(payload: dict) -> dict:
    a = payload.get("a", 0)
    b = payload.get("b", 0)

    logger.info(f"math::add called in Python with a={a}, b={b}")

    result = {"c": a + b}

    return result


worker.register_function("math::add", add_handler)

print("Math worker started - listening for calls")