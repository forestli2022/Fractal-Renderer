using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CollisionDetection1 : MonoBehaviour
{
    public float size;
    private GameObject DistanceFunction;
    private GameObject Camera;
    private RaymarchCamera1 rc;

    // Start is called before the first frame update
    void Start()
    {
        transform.position = new Vector3(0, 0, 0);
        Camera = GameObject.Find("Main Camera");
        rc = Camera.GetComponent<RaymarchCamera1>();
    }

    // Update is called once per frame
    void Update()
    {
        // detect collision
        if (get_distance(transform.position) < size)
        {
            Debug.Log("collision");
        }
    }

    private float get_distance(Vector3 p)
    {
        return 0;
    }
}
