def compute_list_self_weights(list_slider_rating, list_received_rating):
    """Compute the list of self weights for each user over T time steps.

    According to Degroot's model, the self weight of a user is computed as follows:
        X_t+1 = (self_weight) * X_t + (1 - self_weight) * M_t
        where X_t is the slider rating of the user at time t, and M_t is the rating received by the user at time t.

    Args:
        list_slider_rating (list of float): the ratings the user reported using a slider. Have a length of T
        list_received_rating (list of float): the ratings the user received from other users. Have a length of T-1. There is no received rating at time 1.
    Returns:
        list_self_weights (list of float): the self weights of the user over T time steps. Have a length of T-1. There is no self weight at time 1.
    """
    T = len(list_slider_rating)
    assert T == len(list_received_rating) + 1, "Length of list_slider_rating should be 1 + length of list_received_rating"

    list_self_weights = []

    # Compute the self weight
    for i in range(T-1):
        x_tplus1 = list_slider_rating[i+1]
        x_t = list_slider_rating[i]
        m_t = list_received_rating[i]

        #default value when division by zero might occur
        if x_t == m_t:
            self_weight = 1
        else:
            self_weight = (x_tplus1 - m_t) / (x_t - m_t)

        list_self_weights.append(self_weight)

    assert len(list_self_weights) == T - 1, "Length of list_self_weights should be 1 less than length of list_slider_rating"
    
    return list_self_weights
    print (list_self_weights)

slider_ratings = [1.0, 2.0, 3.0, 4.0] 
received_ratings = [0.5, 1.5, 2.5]      


result = compute_list_self_weights(slider_ratings, received_ratings)
print(result)

