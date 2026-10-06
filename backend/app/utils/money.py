def validate_price_xof(price_xof: int) -> int:
    if price_xof <= 0:
        raise ValueError("Le prix doit être un entier strictement positif en FCFA")
    return price_xof


def format_fcfa(amount_xof: int) -> str:
    return f"{amount_xof:,}".replace(",", " ") + " FCFA"
