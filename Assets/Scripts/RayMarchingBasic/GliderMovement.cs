using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GliderMovement : MonoBehaviour
{
    public float speed;
    public float rotate_angle;

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        transform.position += transform.forward * speed * Time.deltaTime;
        if (Input.GetKey("right"))
        {
            transform.localRotation *= Quaternion.Euler(0, rotate_angle * Time.deltaTime, 0);
        }
        if (Input.GetKey("left"))
        {
            transform.localRotation *= Quaternion.Euler(0, -rotate_angle * Time.deltaTime, 0);
        }
        if (Input.GetKey("up"))
        {
            transform.localRotation *= Quaternion.Euler(-rotate_angle * Time.deltaTime, 0, 0);
        }
        if (Input.GetKey("down"))
        {
            transform.localRotation *= Quaternion.Euler(rotate_angle * Time.deltaTime, 0, 0);
        }
    }
}
